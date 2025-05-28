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
set DB_USER=your_mysql_username        :: Nama pengguna MySQL Anda
set DB_PASS=your_mysql_password        :: Kata sandi pengguna MySQL Anda
set DB_NAME=ALL_DATABASES             :: Gunakan "ALL_DATABASES" untuk backup semua database
                                      :: Atau daftar database yang dipisahkan koma (misal: "db1,db2,db3")

:: --- KONFIGURASI TELEGRAM ---
set TELEGRAM_BOT_TOKEN=your_bot_token
set TELEGRAM_CHAT_ID=your_chat_id
set ENABLE_TELEGRAM_FILE=false  :: Default: false, set ke true jika ingin mengirim file ke Telegram
set TELEGRAM_FILE_SIZE_LIMIT=50  :: Ukuran maksimal file dalam MB (default: 50MB)

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
set CLOUD_PROVIDER=google_drive

:: Konfigurasi AWS S3
set AWS_BUCKET=your-bucket-name
set AWS_REGION=ap-southeast-1

:: Konfigurasi Google Drive
set RCLONE_REMOTE=gdrive  :: Nama remote rclone yang dikonfigurasi

:: --- KONFIGURASI LOGGING ---
:: Set ke "true" untuk mengaktifkan logging
set ENABLE_LOGGING=true

:: Direktori untuk menyimpan log file
set LOG_DIR=C:\backups\mysql\logs

:: Rotasi log setiap 3 bulan (90 hari)
set LOG_RETENTION_DAYS=90

:: Level log yang akan dicatat (DEBUG, INFO, WARNING, ERROR, CRITICAL)
set LOG_LEVEL=INFO

:: Nama file log dengan format tanggal
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set LOG_FILE=%LOG_DIR%\mysql_backup_%datetime:~0,8%.log

:: --- FUNGSI UNTUK LOGGING ---
:log_message
setlocal
set level=%~1
set message=%~2
set details=%~3

:: Cek level log
if "%level%"=="DEBUG" (
    if not "%LOG_LEVEL%"=="DEBUG" goto :eof
) else if "%level%"=="INFO" (
    if "%LOG_LEVEL%"=="WARNING" goto :eof
    if "%LOG_LEVEL%"=="ERROR" goto :eof
    if "%LOG_LEVEL%"=="CRITICAL" goto :eof
) else if "%level%"=="WARNING" (
    if "%LOG_LEVEL%"=="ERROR" goto :eof
    if "%LOG_LEVEL%"=="CRITICAL" goto :eof
) else if "%level%"=="ERROR" (
    if "%LOG_LEVEL%"=="CRITICAL" goto :eof
)

:: Buat JSON log entry
set timestamp=%date% %time%
set json_log={"timestamp":"%timestamp%","level":"%level%","message":"%message%","details":"%details%"}

if "%ENABLE_LOGGING%"=="true" (
    echo %json_log% >> "%LOG_FILE%"
)
echo %timestamp% [%level%] %message%
endlocal
goto :eof

:: --- FUNGSI UNTUK ROTASI LOG ---
:rotate_logs
if "%ENABLE_LOGGING%"=="true" (
    if %LOG_RETENTION_DAYS% GTR 0 (
        call :log_message "INFO" "Menghapus log yang lebih lama dari %LOG_RETENTION_DAYS% hari..."
        
        :: Kompres log lama
        for /f "tokens=*" %%f in ('dir /b /a-d "%LOG_DIR%\*.log" ^| findstr /v "%datetime:~0,8%"') do (
            if not "%%~nf"=="" (
                %SEVENZIP_PATH% a -tzip "%LOG_DIR%\%%~nf.zip" "%LOG_DIR%\%%f"
                if %ERRORLEVEL% EQU 0 (
                    del "%LOG_DIR%\%%f"
                )
            )
        )
        
        :: Hapus log zip yang lebih lama dari retention period
        powershell -Command "Get-ChildItem '%LOG_DIR%\*.zip' | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-%LOG_RETENTION_DAYS%) } | Remove-Item -Force"
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "INFO" "Pembersihan log lama selesai."
        ) else (
            call :log_message "WARNING" "Gagal membersihkan log lama. Periksa izin atau path."
        )
    ) else (
        call :log_message "INFO" "Rotasi log dinonaktifkan (LOG_RETENTION_DAYS = 0)."
    )
)
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
    -d "parse_mode=HTML" >> "%LOG_FILE%" 2>&1

endlocal
goto :eof

:: --- FUNGSI UNTUK BACKUP DATABASE ---
:backup_database
setlocal
set db_name=%~1
call :log_message "INFO" "Memulai backup database '%db_name%'..." ""

:: Pastikan direktori backup ada
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Buat timestamp untuk nama file
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%
set BACKUP_FILE=%db_name%_%TIMESTAMP%.sql
set FULL_BACKUP_PATH=%BACKUP_DIR%\%BACKUP_FILE%

:: Backup database
mysqldump -u "%DB_USER%" -p"%DB_PASS%" "%db_name%" > "%FULL_BACKUP_PATH%"

:: Cek apakah perintah mysqldump berhasil
if %ERRORLEVEL% EQU 0 (
    call :log_message "INFO" "Backup database berhasil dibuat" "file=%FULL_BACKUP_PATH%"
    endlocal & exit /b 0
) else (
    call :log_message "ERROR" "Backup database gagal" "database=%db_name%"
    endlocal & exit /b 1
)

:: --- FUNGSI UNTUK BACKUP MULTIPLE DATABASES ---
:backup_multiple_databases
setlocal
call :log_message "INFO" "Memulai backup multiple databases..." ""

:: Buat timestamp untuk nama file
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%
set ARCHIVE_FILE=mysql_backup_%TIMESTAMP%.7z
set FULL_ARCHIVE_PATH=%BACKUP_DIR%\%ARCHIVE_FILE%

:: Backup setiap database
set success=true
for %%d in (%DB_NAME%) do (
    call :backup_database "%%d"
    if %ERRORLEVEL% NEQ 0 (
        set success=false
    )
)

:: Kompres semua file SQL ke satu archive
if "%success%"=="true" (
    %SEVENZIP_PATH% a -t7z -m0=lzma2 -mx=9 "%FULL_ARCHIVE_PATH%" "%BACKUP_DIR%\*_%TIMESTAMP%.sql"
    if %ERRORLEVEL% EQU 0 (
        call :log_message "INFO" "Kompresi berhasil" "archive=%FULL_ARCHIVE_PATH%"
        :: Hapus file SQL individual
        del "%BACKUP_DIR%\*_%TIMESTAMP%.sql"
        call :log_message "INFO" "File SQL individual telah dihapus" ""
        endlocal & exit /b 0
    ) else (
        call :log_message "ERROR" "Kompresi gagal" ""
        endlocal & exit /b 1
    )
) else (
    call :log_message "ERROR" "Beberapa database gagal dibackup" ""
    endlocal & exit /b 1
)

:: --- FUNGSI UNTUK ROTASI BACKUP ---
:clean_old_backups
setlocal
if %RETENTION_DAYS% GTR 0 (
    call :log_message "INFO" "Menghapus backup yang lebih lama dari %RETENTION_DAYS% hari..."
    
    :: Gunakan PowerShell untuk menghapus file lama
    powershell -Command "Get-ChildItem '%BACKUP_DIR%\*.7z' | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-%RETENTION_DAYS%) } | Remove-Item -Force"
    
    if %ERRORLEVEL% EQU 0 (
        call :log_message "INFO" "Pembersihan backup lama selesai."
    ) else (
        call :log_message "WARNING" "Gagal membersihkan backup lama. Periksa izin atau path."
    )
) else (
    call :log_message "INFO" "Rotasi backup dinonaktifkan (RETENTION_DAYS = 0)."
)
endlocal
goto :eof

:: --- FUNGSI UNTUK UPLOAD KE CLOUD ---
:upload_to_cloud
setlocal
set file_path=%~1

if "%ENABLE_CLOUD_BACKUP%"=="true" (
    call :log_message "INFO" "Memulai upload ke cloud storage..."
    
    if "%CLOUD_PROVIDER%"=="aws_s3" (
        :: Upload ke AWS S3
        aws s3 cp "%file_path%" "s3://%AWS_BUCKET%/mysql_backups/%file_path:~-1%" ^
            --region "%AWS_REGION%" ^
            --storage-class STANDARD_IA
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "INFO" "Upload ke AWS S3 berhasil"
            call :send_telegram_notification "INFO" "✅ Backup berhasil diupload ke AWS S3"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR" "Upload ke AWS S3 gagal"
            call :send_telegram_notification "ERROR" "❌ Gagal mengupload backup ke AWS S3"
            endlocal & exit /b 1
        )
    ) else if "%CLOUD_PROVIDER%"=="google_drive" (
        :: Upload ke Google Drive menggunakan rclone
        rclone copy "%file_path%" "%RCLONE_REMOTE%:mysql_backups/"
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "INFO" "Upload ke Google Drive berhasil"
            call :send_telegram_notification "INFO" "✅ Backup berhasil diupload ke Google Drive"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR" "Upload ke Google Drive gagal"
            call :send_telegram_notification "ERROR" "❌ Gagal mengupload backup ke Google Drive"
            endlocal & exit /b 1
        )
    ) else if "%CLOUD_PROVIDER%"=="dropbox" (
        :: Upload ke Dropbox
        dropbox_uploader.bat upload "%file_path%" "/mysql_backups/"
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "INFO" "Upload ke Dropbox berhasil"
            call :send_telegram_notification "INFO" "✅ Backup berhasil diupload ke Dropbox"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR" "Upload ke Dropbox gagal"
            call :send_telegram_notification "ERROR" "❌ Gagal mengupload backup ke Dropbox"
            endlocal & exit /b 1
        )
    ) else if "%CLOUD_PROVIDER%"=="backblaze_b2" (
        :: Upload ke Backblaze B2
        b2 upload-file "%AWS_BUCKET%" "%file_path%" "mysql_backups/%file_path:~-1%"
        
        if %ERRORLEVEL% EQU 0 (
            call :log_message "INFO" "Upload ke Backblaze B2 berhasil"
            call :send_telegram_notification "INFO" "✅ Backup berhasil diupload ke Backblaze B2"
            endlocal & exit /b 0
        ) else (
            call :log_message "ERROR" "Upload ke Backblaze B2 gagal"
            call :send_telegram_notification "ERROR" "❌ Gagal mengupload backup ke Backblaze B2"
            endlocal & exit /b 1
        )
    ) else (
        call :log_message "ERROR" "Provider cloud tidak dikenali"
        endlocal & exit /b 1
    )
) else (
    call :log_message "INFO" "Cloud backup dinonaktifkan"
    endlocal & exit /b 0
)

:: ==============================================================================
:: --- JALANKAN PROSES BACKUP ---
:: ==============================================================================
:: Buat direktori log jika belum ada
if "%ENABLE_LOGGING%"=="true" (
    if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
    call :rotate_logs
)

call :log_message "INFO" "----------------------------------------------------" ""
call :log_message "INFO" "Memulai proses backup MySQL..." ""

:: Kirim notifikasi mulai backup
call :send_telegram_notification "STARTED" "Memulai proses backup database..."

:: Panggil fungsi backup database
if "%DB_NAME%"=="ALL_DATABASES" (
    :: Backup semua database
    call :backup_multiple_databases
) else (
    :: Backup database yang ditentukan
    call :backup_multiple_databases
)

if %ERRORLEVEL% EQU 0 (
    call :log_message "INFO" "Proses backup dan kompresi selesai dengan sukses." ""
    call :send_telegram_notification "SUCCESS" "✅ Backup dan kompresi selesai dengan sukses."
    
    :: Upload ke cloud storage
    call :upload_to_cloud "%FULL_ARCHIVE_PATH%"
    
    call :clean_old_backups
) else (
    call :log_message "ERROR" "Proses backup selesai dengan ERROR." ""
    call :send_telegram_notification "ERROR" "❌ Gagal pada proses backup database."
)

call :log_message "INFO" "----------------------------------------------------" ""
