# MySQL Backup Script for Windows

Script otomatis untuk backup database MySQL dengan fitur kompresi 7z dan notifikasi Telegram.

## Fitur

- Backup otomatis database MySQL menggunakan mysqldump
- Kompresi file backup ke format 7z untuk menghemat ruang
- Opsi untuk backup database tunggal atau semua database
- Pembersihan otomatis backup lama berdasarkan kebijakan retensi
- Notifikasi real-time melalui Telegram
- Upload otomatis ke cloud storage (AWS S3, Google Drive, Dropbox, Backblaze B2)
- Pengiriman file backup langsung ke Telegram (opsional, dinonaktifkan secara default)

## Persyaratan

1. MySQL Server dan mysqldump
2. 7-Zip untuk kompresi
3. PowerShell untuk notifikasi Telegram
4. Cloud storage tools (pilih salah satu):
   - AWS CLI untuk AWS S3
   - rclone untuk Google Drive
   - Dropbox Uploader untuk Dropbox
   - B2 CLI untuk Backblaze B2

### Instalasi Dependensi

1. **MySQL Server**
   - Download dan install MySQL Server dari [mysql.com](https://dev.mysql.com/downloads/mysql/)
   - Pastikan mysqldump.exe tersedia di PATH sistem

2. **7-Zip**
   - Download dan install 7-Zip dari [7-zip.org](https://7-zip.org/)
   - Pastikan path ke 7z.exe sudah benar di script

3. **Cloud Storage Tools**

   #### AWS S3
   ```powershell
   # Install AWS CLI
   pip install awscli
   
   # Konfigurasi AWS
   aws configure
   ```

   #### Google Drive
   ```powershell
   # Install rclone
   winget install rclone
   
   # Konfigurasi rclone
   rclone config
   ```
   
   Langkah-langkah konfigurasi rclone:
   1. Ketik `n` untuk membuat remote baru
   2. Beri nama remote (misal: `gdrive`)
   3. Pilih `drive` untuk Google Drive
   4. Pilih `y` untuk menggunakan browser untuk autentikasi
   5. Buka browser dan login ke akun Google Anda
   6. Berikan izin yang diminta
   7. Pilih `y` untuk konfigurasi lanjutan
   8. Pilih `1` untuk root folder
   9. Pilih `n` untuk tidak membatasi akses ke folder tertentu
   10. Pilih `y` untuk konfirmasi
   
   Buat folder di Google Drive:
   ```powershell
   rclone mkdir gdrive:mysql_backups
   ```
   
   Test konfigurasi:
   ```powershell
   rclone lsd gdrive:
   ```

   #### Dropbox
   ```powershell
   # Download Dropbox Uploader
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.bat" -OutFile "dropbox_uploader.bat"
   ```

   #### Backblaze B2
   ```powershell
   # Install B2 CLI
   pip install b2
   
   # Konfigurasi B2
   b2 authorize-account
   ```

## Konfigurasi Cepat

1. Edit file `mysql_backup.bat` dan sesuaikan konfigurasi berikut:

   ```batch
   :: Konfigurasi Database
   set DB_USER=your_username
   set DB_PASS=your_password
   set DB_NAME=your_database  :: Atau "ALL_DATABASES" untuk backup semua database
   
   :: Konfigurasi Telegram
   set TELEGRAM_BOT_TOKEN=your_bot_token
   set TELEGRAM_CHAT_ID=your_chat_id
   set ENABLE_TELEGRAM_FILE=false  :: Default: false, set ke true jika ingin mengirim file ke Telegram
   set TELEGRAM_FILE_SIZE_LIMIT=50  :: Ukuran maksimal file dalam MB (default: 50MB)
   
   :: Konfigurasi Cloud Storage
   set ENABLE_CLOUD_BACKUP=true
   set CLOUD_PROVIDER=google_drive  :: Pilih: aws_s3, google_drive, dropbox, backblaze_b2
   
   :: Konfigurasi Google Drive
   set RCLONE_REMOTE=gdrive  :: Nama remote rclone yang dikonfigurasi
   ```

2. Konfigurasi Telegram Bot:

   a. Buat Bot Telegram:
   - Buka Telegram dan cari "@BotFather"
   - Kirim perintah `/newbot`
   - Ikuti instruksi untuk membuat bot baru
   - Simpan BOT_TOKEN yang diberikan

   b. Dapatkan Chat ID:
   - Kirim pesan ke bot baru Anda
   - Buka browser dan akses: `https://api.telegram.org/bot<BOT_TOKEN>/getUpdates`
   - Cari `"chat":{"id":` dalam response

   c. Konfigurasi Bot untuk File:
   - Pastikan bot memiliki izin untuk mengirim file
   - Bot harus memiliki akses ke chat/group
   - Untuk group, tambahkan bot sebagai admin

3. Konfigurasi Cloud Storage:

   #### AWS S3
   ```powershell
   aws configure
   # Masukkan AWS Access Key ID
   # Masukkan AWS Secret Access Key
   # Masukkan default region
   ```

   #### Google Drive
   ```powershell
   # Pastikan rclone sudah terkonfigurasi dengan benar
   rclone config show
   
   # Test koneksi ke Google Drive
   rclone lsd gdrive:
   
   # Test upload file
   rclone copy test.txt gdrive:mysql_backups/
   ```

   #### Dropbox
   ```powershell
   # Edit file dropbox_uploader.bat
   # Masukkan Dropbox API token
   ```

   #### Backblaze B2
   ```powershell
   b2 authorize-account
   # Masukkan account ID dan application key
   ```

4. Jalankan script secara manual untuk testing:
   ```batch
   mysql_backup.bat
   ```
   Anda akan menerima notifikasi Telegram tentang status backup dan file backup (jika diaktifkan).

## Otomatisasi

Untuk menjalankan backup secara otomatis, gunakan Task Scheduler Windows:

1. Buka Task Scheduler
2. Klik "Create Basic Task"
3. Beri nama dan deskripsi
4. Pilih trigger (misal: Daily)
5. Pilih waktu (misal: 2:00 AM)
6. Pilih "Start a program"
7. Browse ke lokasi `mysql_backup.bat`
8. Selesai

## Notifikasi Telegram

Script akan mengirim notifikasi untuk berbagai status:

1. Backup dimulai:
   ```
   🔄 Memulai backup database...
   Database: your_database
   Waktu: 2024-02-20 02:00:00
   ```

2. Backup berhasil:
   ```
   ✅ Backup dan kompresi selesai dengan sukses.
   File: C:\backups\mysql\your_database_20240220_020000.7z
   Ukuran: 1.2 GB
   ```

3. Upload ke cloud berhasil:
   ```
   ✅ Backup berhasil diupload ke Google Drive
   Lokasi: gdrive:mysql_backups/your_database_20240220_020000.7z
   ```

4. File dikirim ke Telegram:
   ```
   📤 File backup berhasil dikirim ke Telegram
   Nama file: your_database_20240220_020000.7z
   Ukuran: 1.2 GB
   ```

5. Error:
   ```
   ❌ Gagal pada proses backup database.
   Error: Access denied for user 'your_username'@'localhost'
   ```

## Catatan Penting

1. **Keamanan**:
   - Simpan kredensial database dengan aman
   - Gunakan file konfigurasi terpisah untuk kredensial
   - Batasi akses ke script dengan permission yang tepat
   - Enkripsi kredensial cloud storage
   - Jaga kerahasiaan token bot Telegram

2. **Lokasi Backup**:
   - Pastikan direktori backup memiliki ruang yang cukup
   - Gunakan lokasi terpisah dari database
   - Pertimbangkan untuk menggunakan drive terpisah

3. **Testing**:
   - Test proses restore secara berkala
   - Verifikasi integritas backup
   - Test notifikasi Telegram
   - Test upload ke cloud storage
   - Test pengiriman file ke Telegram

4. **Monitoring**:
   - Periksa log file secara berkala
   - Monitor penggunaan ruang disk
   - Monitor biaya cloud storage
   - Set up monitoring untuk notifikasi error
   - Monitor ukuran file yang dikirim ke Telegram

5. **Cloud Storage**:
   - Pilih storage class yang sesuai dengan kebutuhan
   - Atur lifecycle policy untuk menghemat biaya
   - Enkripsi data sebelum upload
   - Verifikasi upload secara berkala

6. **Telegram File Upload**:
   - Perhatikan batas ukuran file (50MB)
   - Pastikan koneksi internet stabil
   - Monitor penggunaan bandwidth
   - Pertimbangkan kompresi untuk file besar

## Troubleshooting

1. **Error "Access denied"**:
   - Periksa kredensial MySQL
   - Pastikan user memiliki hak akses yang cukup

2. **Error kompresi**:
   - Periksa ruang disk yang tersedia
   - Pastikan 7-Zip terinstal dengan benar
   - Periksa path ke 7z.exe

3. **Error Telegram**:
   - Periksa token bot dan chat ID
   - Pastikan bot sudah diaktifkan
   - Periksa koneksi internet
   - Pastikan bot memiliki izin untuk mengirim file
   - Periksa batas ukuran file

4. **Error Cloud Storage**:
   - Periksa kredensial cloud storage
   - Pastikan bucket/folder sudah dibuat
   - Periksa permission dan policy
   - Verifikasi koneksi internet
   - Pastikan tools cloud storage terinstal dengan benar
   - Untuk Google Drive, pastikan rclone terkonfigurasi dengan benar
   - Periksa nama remote rclone di konfigurasi script

5. **Error File Upload ke Telegram**:
   - Periksa ukuran file (maksimal 50MB)
   - Pastikan koneksi internet stabil
   - Periksa izin bot untuk mengirim file
   - Coba kompresi file jika terlalu besar
