# MySQL Backup Script for Windows

Script otomatis untuk backup database MySQL dengan fitur kompresi 7z dan notifikasi Telegram.

## Fitur

- Backup otomatis database MySQL menggunakan mysqldump
- Kompresi file backup ke format 7z untuk menghemat ruang
- Opsi untuk backup database tunggal atau semua database
- Pembersihan otomatis backup lama berdasarkan kebijakan retensi
- Notifikasi real-time melalui Telegram
- Upload otomatis ke cloud storage (AWS S3, Google Drive, Dropbox, Backblaze B2)

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
   
   :: Konfigurasi Cloud Storage
   set ENABLE_CLOUD_BACKUP=true
   set CLOUD_PROVIDER=aws_s3  :: Pilih: aws_s3, google_drive, dropbox, backblaze_b2
   
   :: Konfigurasi AWS S3
   set AWS_BUCKET=your-bucket-name
   set AWS_REGION=ap-southeast-1
   ```

2. Konfigurasi Cloud Storage:

   #### AWS S3
   ```powershell
   aws configure
   # Masukkan AWS Access Key ID
   # Masukkan AWS Secret Access Key
   # Masukkan default region
   ```

   #### Google Drive
   ```powershell
   rclone config
   # Ikuti petunjuk untuk mengkonfigurasi Google Drive
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

3. Jalankan script secara manual untuk testing:
   ```batch
   mysql_backup.bat
   ```
   Anda akan menerima notifikasi Telegram tentang status backup.

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
   ✅ Backup berhasil diupload ke AWS S3
   Lokasi: s3://your-bucket/mysql_backups/your_database_20240220_020000.7z
   ```

4. Error:
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

2. **Lokasi Backup**:
   - Pastikan direktori backup memiliki ruang yang cukup
   - Gunakan lokasi terpisah dari database
   - Pertimbangkan untuk menggunakan drive terpisah

3. **Testing**:
   - Test proses restore secara berkala
   - Verifikasi integritas backup
   - Test notifikasi Telegram
   - Test upload ke cloud storage

4. **Monitoring**:
   - Periksa log file secara berkala
   - Monitor penggunaan ruang disk
   - Monitor biaya cloud storage
   - Set up monitoring untuk notifikasi error

5. **Cloud Storage**:
   - Pilih storage class yang sesuai dengan kebutuhan
   - Atur lifecycle policy untuk menghemat biaya
   - Enkripsi data sebelum upload
   - Verifikasi upload secara berkala

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

4. **Error Cloud Storage**:
   - Periksa kredensial cloud storage
   - Pastikan bucket/folder sudah dibuat
   - Periksa permission dan policy
   - Verifikasi koneksi internet
   - Pastikan tools cloud storage terinstal dengan benar
