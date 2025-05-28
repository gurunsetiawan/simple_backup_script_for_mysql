@echo off
REM ==============================================================================
REM Script Otomatisasi Backup Database MySQL
REM Deskripsi: Melakukan backup database MySQL menggunakan mysqldump,
REM            kemudian mengkompresinya ke dalam format 7z dengan penamaan
REM            berdasarkan tanggal, bulan, dan tahun.
REM            Juga menyertakan fitur untuk menghapus backup lama.
REM ==============================================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- KONFIGURASI DATABASE ---
REM Ganti nilai-nilai berikut dengan kredensial database Anda.
REM Jika ingin membackup semua database, set DB_NAME="ALL_DATABASES"
SET DB_USER=your_mysql_username        REM Nama pengguna MySQL Anda
SET DB_PASS=your_mysql_password        REM Kata sandi pengguna MySQL Anda
SET DB_NAME=your_database_name         REM Nama database yang akan dibackup (misal: "my_app_db")
                                     REM Atau gunakan "ALL_DATABASES" untuk backup semua database

REM --- KONFIGURASI DIREKTORI & PATH APLIKASI ---
REM Direktori tempat file backup akan disimpan.
SET BACKUP_DIR=C:\MySQL_Backups      REM Contoh: C:\Users\YourUser\Documents\MySQL_Backups

REM Path lengkap ke mysqldump.exe (sesuaikan dengan instalasi MySQL Anda)
REM Contoh: "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe"
SET MYSQLDUMP_PATH="C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe"

REM Path lengkap ke 7z.exe (sesuaikan dengan instalasi 7-Zip Anda)
REM Contoh: "C:\Program Files\7-Zip\7z.exe"
SET PATH_7Z="C:\Program Files\7-Zip\7z.exe"

REM --- KONFIGURASI RETENSI (OPSIONAL) ---
REM Jumlah hari untuk menyimpan file backup. File yang lebih lama akan dihapus.
REM Set ke 0 atau komentar baris ini jika tidak ingin menghapus backup lama.
SET RETENTION_DAYS=7                 REM Contoh: 7 hari

REM --- VARIABEL PENAMAAN FILE ---
REM Membuat timestamp unik untuk nama file backup.
REM Format: YYYY-MM-DD_HH-MM-SS
REM Mengambil tanggal dan waktu saat ini
FOR /F "tokens=1-4 delims=/ " %%i IN ('date /t') DO (
    SET current_date_full=%%i
)
FOR /F "tokens=1-2 delims=:" %%i IN ('time /t') DO (
    SET current_hour=%%i
    SET current_minute=%%j
)

REM Format tanggal ke YYYY-MM-DD
SET YEAR=!current_date_full:~10,4!
SET MONTH=!current_date_full:~4,2!
SET DAY=!current_date_full:~7,2!
REM Menambahkan RANDOM agar lebih unik karena TIME /t hanya memberikan jam dan menit, tidak detik
SET TIMESTAMP=!YEAR!-!MONTH!-!DAY!_!current_hour!-!current_minute!-!RANDOM!

REM Nama file SQL sebelum dikompresi
SET BACKUP_FILE=!DB_NAME!_!TIMESTAMP!.sql

REM Nama file archive 7z
SET ARCHIVE_FILE=!DB_NAME!_!TIMESTAMP!.7z

REM Path lengkap untuk file SQL dan 7z
SET FULL_BACKUP_PATH=!BACKUP_DIR!\!BACKUP_FILE!
SET FULL_ARCHIVE_PATH=!BACKUP_DIR!\!ARCHIVE_FILE!

REM --- FUNGSI UNTUK LOGGING ---
REM Fungsi sederhana untuk mencetak pesan ke konsol dan log file.
:log_message
ECHO %DATE% %TIME% - %*
GOTO :EOF

REM --- FUNGSI UNTUK BACKUP DATABASE ---
:backup_database
CALL :log_message "Memulai backup database '%DB_NAME%'..."

REM Pastikan direktori backup ada
IF NOT EXIST "%BACKUP_DIR%" MD "%BACKUP_DIR%"

IF "%DB_NAME%"=="ALL_DATABASES" (
    REM Backup semua database
    "%MYSQLDUMP_PATH%" -u %DB_USER% -p%DB_PASS% --all-databases > "%FULL_BACKUP_PATH%"
) ELSE (
    REM Backup satu database spesifik
    "%MYSQLDUMP_PATH%" -u %DB_USER% -p%DB_PASS% %DB_NAME% > "%FULL_BACKUP_PATH%"
)

REM Cek apakah perintah mysqldump berhasil
IF %ERRORLEVEL% NEQ 0 (
    CALL :log_message "ERROR: Backup database gagal!"
    EXIT /B 1 REM Gagal
) ELSE (
    CALL :log_message "Backup database berhasil dibuat: '%FULL_BACKUP_PATH%'"
    EXIT /B 0 REM Sukses
)

REM --- FUNGSI UNTUK KOMPRESI MENGGUNAKAN 7Z ---
:compress_backup
CALL :log_message "Memulai kompresi file backup ke '%FULL_ARCHIVE_PATH%'..."

REM Parameter kompresi 7z:
REM a      : Tambahkan ke arsip
REM -t7z   : Tipe arsip 7z
REM -m0=lzma2: Menggunakan algoritma kompresi LZMA2 (efisien)
REM -mx=9  : Tingkat kompresi maksimal (0=tanpa kompresi, 9=maksimal)
"%PATH_7Z%" a -t7z -m0=lzma2 -mx=9 "%FULL_ARCHIVE_PATH%" "%FULL_BACKUP_PATH%"

REM Cek apakah perintah 7z berhasil
IF %ERRORLEVEL% NEQ 0 (
    CALL :log_message "ERROR: Kompresi gagal!"
    EXIT /B 1 REM Gagal
) ELSE (
    CALL :log_message "Kompresi berhasil. File archive: '%FULL_ARCHIVE_PATH%'"
    REM Hapus file .sql asli setelah berhasil dikompresi untuk menghemat ruang
    DEL "%FULL_BACKUP_PATH%"
    CALL :log_message "File SQL asli ('%BACKUP_FILE%') telah dihapus."
    EXIT /B 0 REM Sukses
)

REM --- FUNGSI UNTUK ROTASI BACKUP ---
REM Menghapus file backup 7z yang lebih lama dari RETENTION_DAYS
:clean_old_backups
IF %RETENTION_DAYS% GTR 0 (
    CALL :log_message "Menghapus backup yang lebih lama dari %RETENTION_DAYS% hari..."
    REM forfiles: Mencari file
    REM /p "%BACKUP_DIR%": Di direktori ini
    REM /s: Juga di subdirektori (opsional, bisa dihapus jika tidak perlu)
    REM /m *.7z: Dengan nama yang diakhiri .7z
    REM /d -%RETENTION_DAYS%: Dimodifikasi lebih dari %RETENTION_DAYS% hari yang lalu
    REM /c "cmd /c del @file": Hapus file yang ditemukan
    forfiles /p "%BACKUP_DIR%" /m *.7z /d -%RETENTION_DAYS% /c "cmd /c del @file"

    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_message "PERINGATAN: Gagal membersihkan backup lama. Periksa izin atau path."
    ) ELSE (
        CALL :log_message "Pembersihan backup lama selesai."
    )
) ELSE (
    CALL :log_message "Rotasi backup dinonaktifkan (RETENTION_DAYS = 0)."
)
EXIT /B 0

REM ==============================================================================
REM --- JALANKAN PROSES BACKUP ---
REM ==============================================================================
CALL :log_message "----------------------------------------------------"
CALL :log_message "Memulai proses backup MySQL..."

REM Panggil fungsi backup database
CALL :backup_database
IF %ERRORLEVEL% EQU 0 (
    REM Jika backup database berhasil, lanjutkan dengan kompresi
    CALL :compress_backup
    IF %ERRORLEVEL% EQU 0 (
        CALL :log_message "Proses backup dan kompresi selesai dengan sukses."
        CALL :clean_old_backups REM Panggil fungsi pembersihan setelah backup baru dibuat
    ) ELSE (
        CALL :log_message "Proses backup selesai dengan ERROR pada kompresi."
    )
) ELSE (
    CALL :log_message "Proses backup selesai dengan ERROR pada backup database."
)

CALL :log_message "----------------------------------------------------"
ENDLOCAL
