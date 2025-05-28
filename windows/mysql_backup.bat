@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: Script Otomatisasi Backup Database MySQL untuk Windows
:: Deskripsi: Melakukan backup database MySQL menggunakan mysqldump,
::            kemudian mengkompresinya ke dalam format 7z dengan penamaan
::            berdasarkan tanggal, bulan, dan tahun.
::            Juga menyertakan fitur untuk menghapus backup lama.
:: ==============================================================================

:: --- KONFIGURASI DATABASE ---
:: Ganti nilai-nilai berikut dengan kredensial database Anda.
:: Jika ingin membackup semua database, set DB_NAME=ALL_DATABASES
set DB_USER=your_mysql_username        :: Nama pengguna MySQL Anda
set DB_PASS=your_mysql_password        :: Kata sandi pengguna MySQL Anda
set DB_NAME=your_database_name         :: Nama database yang akan dibackup (misal: "my_app_db")
                                      :: Atau gunakan "ALL_DATABASES" untuk backup semua database

:: --- KONFIGURASI TELEGRAM ---
set TELEGRAM_BOT_TOKEN=your_bot_token_here    :: Token bot Telegram Anda
set TELEGRAM_CHAT_ID=your_chat_id_here        :: Chat ID untuk notifikasi

:: --- KONFIGURASI DIREKTORI & PATH APLIKASI ---
:: Direktori tempat file backup akan disimpan.
set BACKUP_DIR=C:\backups\mysql      :: Contoh: C:\backups\mysql

:: Path ke aplikasi 7-Zip (sesuaikan dengan lokasi instalasi Anda)
set SEVENZIP_PATH="C:\Program Files\7-Zip\7z.exe"

:: --- KONFIGURASI RETENSI (OPSIONAL) ---
:: Jumlah hari untuk menyimpan file backup. File yang lebih lama akan dihapus.
:: Set ke 0 atau komentar baris ini jika tidak ingin menghapus backup lama.
set RETENTION_DAYS=7                     :: Contoh: 7 hari

:: --- KONFIGURASI CLOUD STORAGE ---
:: Set ke "true" untuk mengaktifkan upload ke cloud
set ENABLE_CLOUD_BACKUP=true

:: Pilih provider cloud (aws_s3, google_drive, dropbox, backblaze_b2)
set CLOUD_PROVIDER=aws_s3

:: Konfigurasi AWS S3
set AWS_BUCKET=your-bucket-name
set AWS_REGION=ap-southeast-1

:: --- FUNGSI UNTUK LOGGING ---
:log_message
echo %date% %time% - %*
goto :eof

:: --- FUNGSI UNTUK KIRIM NOTIFIKASI TELEGRAM ---
:send_telegram_notification
setlocal
set status=%~1
set message=%~2

:: Buat pesan lengkap
set full_message=🔔 MySQL Backup Notification

📊 Status: %status%
⏰ Time: %date% %time%
📁 Database: %DB_NAME%

%message%

:: URL encode pesan (menggunakan PowerShell)
powershell -Command "$message = '%full_message%'; $message = [System.Web.HttpUtility]::UrlEncode($message); $message"

:: Kirim notifikasi menggunakan curl
curl -s -X POST "https://api.telegram.org/bot%TELEGRAM_BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%TELEGRAM_CHAT_ID%" ^
    -d "text=%full_message%" ^
    -d "parse_mode=HTML" > nul 2>&1

endlocal
goto :eof

:: --- FUNGSI UNTUK BACKUP DATABASE ---
:backup_database
setlocal
call :log_message "Memulai backup database '%DB_NAME%'..."

:: Pastikan direktori backup ada
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Buat timestamp untuk nama file
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%
set BACKUP_FILE=%DB_NAME%_%TIMESTAMP%.sql
set FULL_BACKUP_PATH=%BACKUP_DIR%\%BACKUP_FILE%

:: Backup database
if "%DB_NAME%"=="ALL_DATABASES" (
    mysqldump -u "%DB_USER%" -p"%DB_PASS%" --all-databases > "%FULL_BACKUP_PATH%"
) else (
    mysqldump -u "%DB_USER%" -p"%DB_PASS%" "%DB_NAME%" > "%FULL_BACKUP_PATH%"
)

:: Cek apakah perintah mysqldump berhasil
if %ERRORLEVEL% EQU 0 (
    call :log_message "Backup database berhasil dibuat: '%FULL_BACKUP_PATH%'"
    endlocal & exit /b 0
) else (
    call :log_message "ERROR: Backup database gagal!"
    endlocal & exit /b 1
)

:: --- FUNGSI UNTUK KOMPRESI MENGGUNAKAN 7Z ---
:compress_backup
setlocal
call :log_message "Memulai kompresi file backup..."

:: Nama file archive 7z
set ARCHIVE_FILE=%DB_NAME%_%TIMESTAMP%.7z
set FULL_ARCHIVE_PATH=%BACKUP_DIR%\%ARCHIVE_FILE%

:: Kompresi menggunakan 7z
%SEVENZIP_PATH% a -t7z -m0=lzma2 -mx=9 "%FULL_ARCHIVE_PATH%" "%FULL_BACKUP_PATH%"

:: Cek apakah perintah 7z berhasil
if %ERRORLEVEL% EQU 0 (
    call :log_message "Kompresi berhasil. File archive: '%FULL_ARCHIVE_PATH%'"
    :: Hapus file .sql asli setelah berhasil dikompresi
    del "%FULL_BACKUP_PATH%"
    call :log_message "File SQL asli ('%BACKUP_FILE%') telah dihapus."
    endlocal & exit /b 0
) else (
    call :log_message "ERROR: Kompresi gagal!"
    endlocal & exit /b 1
)

:: --- FUNGSI UNTUK ROTASI BACKUP ---
:clean_old_backups
setlocal
if %RETENTION_DAYS% GTR 0 (
    call :log_message "Menghapus backup yang lebih lama dari %RETENTION_DAYS% hari..."
    
    :: Gunakan PowerShell untuk menghapus file lama
    powershell -Command "Get-ChildItem '%BACKUP_DIR%\*.7z' | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-%RETENTION_DAYS%) } | Remove-Item -Force"
    
    if %ERRORLEVEL% EQU 0 (
        call :log_message "Pembersihan backup lama selesai."
    ) else (
        call :log_message "PERINGATAN: Gagal membersihkan backup lama. Periksa izin atau path."
    )
) else (
    call :log_message "Rotasi backup dinonaktifkan (RETENTION_DAYS = 0)."
)
endlocal
goto :eof

:: --- FUNGSI UNTUK UPLOAD KE CLOUD ---
:upload_to_cloud
setlocal
set file_path=%~1

if "%ENABLE_CLOUD_BACKUP%"=="true" (
    call :log_message "Memulai upload ke cloud storage..."
    
    if "%CLOUD_PROVIDER%"=="aws_s3" (
        :: Upload ke AWS S3
        aws s3 cp "%file_path%" "s3://%AWS_BUCKET%/mysql_backups/%file_path:~-1%" ^
            --region "%AWS_REGION%" ^
            --storage-class STANDARD_IA
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "Upload ke AWS S3 berhasil"
            call :send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke AWS S3"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR: Upload ke AWS S3 gagal"
            call :send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke AWS S3"
            endlocal & exit /b 1
        )
    ) else if "%CLOUD_PROVIDER%"=="google_drive" (
        :: Upload ke Google Drive menggunakan rclone
        rclone copy "%file_path%" "remote:mysql_backups/"
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "Upload ke Google Drive berhasil"
            call :send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke Google Drive"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR: Upload ke Google Drive gagal"
            call :send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke Google Drive"
            endlocal & exit /b 1
        )
    ) else if "%CLOUD_PROVIDER%"=="dropbox" (
        :: Upload ke Dropbox
        dropbox_uploader.bat upload "%file_path%" "/mysql_backups/"
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "Upload ke Dropbox berhasil"
            call :send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke Dropbox"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR: Upload ke Dropbox gagal"
            call :send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke Dropbox"
            endlocal & exit /b 1
        )
    ) else if "%CLOUD_PROVIDER%"=="backblaze_b2" (
        :: Upload ke Backblaze B2
        b2 upload-file "%AWS_BUCKET%" "%file_path%" "mysql_backups/%file_path:~-1%"
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "Upload ke Backblaze B2 berhasil"
            call :send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke Backblaze B2"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR: Upload ke Backblaze B2 gagal"
            call :send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke Backblaze B2"
            endlocal & exit /b 1
        )
    ) else (
        call :log_message "ERROR: Provider cloud tidak dikenali"
        endlocal & exit /b 1
    )
) else (
    call :log_message "Cloud backup dinonaktifkan"
    endlocal & exit /b 0
)

:: ==============================================================================
:: --- JALANKAN PROSES BACKUP ---
:: ==============================================================================
call :log_message "----------------------------------------------------"
call :log_message "Memulai proses backup MySQL..."

:: Kirim notifikasi mulai backup
call :send_telegram_notification "STARTED" "Memulai proses backup database..."

:: Panggil fungsi backup database
call :backup_database
if %ERRORLEVEL% EQU 0 (
    :: Jika backup database berhasil, lanjutkan dengan kompresi
    call :compress_backup
    if %ERRORLEVEL% EQU 0 (
        call :log_message "Proses backup dan kompresi selesai dengan sukses."
        call :send_telegram_notification "SUCCESS" "✅ Backup dan kompresi selesai dengan sukses."
        
        :: Upload ke cloud storage
        call :upload_to_cloud "%FULL_ARCHIVE_PATH%"
        
        call :clean_old_backups
    ) else (
        call :log_message "Proses backup selesai dengan ERROR pada kompresi."
        call :send_telegram_notification "ERROR" "❌ Gagal pada proses kompresi backup."
    )
) else (
    call :log_message "Proses backup selesai dengan ERROR pada backup database."
    call :send_telegram_notification "ERROR" "❌ Gagal pada proses backup database."
)

call :log_message "----------------------------------------------------"
