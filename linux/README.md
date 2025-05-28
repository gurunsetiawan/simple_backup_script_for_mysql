# MySQL Backup Script for Linux

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
3. curl untuk notifikasi Telegram
4. Cloud storage tools (pilih salah satu):
   - AWS CLI untuk AWS S3
   - rclone untuk Google Drive
   - Dropbox Uploader untuk Dropbox
   - B2 CLI untuk Backblaze B2

### Instalasi Dependensi

#### Debian/Ubuntu
```bash
# MySQL
sudo apt-get update
sudo apt-get install mysql-client

# 7-Zip
sudo apt-get install p7zip-full

# curl
sudo apt-get install curl

# Cloud Storage Tools
# AWS CLI
sudo apt-get install awscli

# rclone (Google Drive)
curl https://rclone.org/install.sh | sudo bash

# Dropbox Uploader
wget https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh
chmod +x dropbox_uploader.sh

# B2 CLI
pip install b2
```

#### CentOS/RHEL
```bash
# MySQL
sudo yum install mysql

# 7-Zip
sudo yum install p7zip p7zip-plugins

# curl
sudo yum install curl

# Cloud Storage Tools
# AWS CLI
sudo yum install awscli

# rclone (Google Drive)
curl https://rclone.org/install.sh | sudo bash

# Dropbox Uploader
wget https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh
chmod +x dropbox_uploader.sh

# B2 CLI
pip install b2
```

## Konfigurasi Cepat

1. Edit file `mysql_backup.sh` dan sesuaikan konfigurasi berikut:

   ```bash
   # Konfigurasi Database
   DB_USER="your_username"
   DB_PASS="your_password"
   DB_NAME="your_database"  # Atau "ALL_DATABASES" untuk backup semua database
   
   # Konfigurasi Telegram
   TELEGRAM_BOT_TOKEN="your_bot_token"
   TELEGRAM_CHAT_ID="your_chat_id"
   ENABLE_TELEGRAM_FILE=true  # Set ke true untuk mengirim file ke Telegram
   TELEGRAM_FILE_SIZE_LIMIT=50  # Ukuran maksimal file dalam MB (default: 50MB)
   
   # Konfigurasi Cloud Storage
   ENABLE_CLOUD_BACKUP=true
   CLOUD_PROVIDER="aws_s3"  # Pilih: aws_s3, google_drive, dropbox, backblaze_b2
   
   # Konfigurasi AWS S3
   AWS_BUCKET="your-bucket-name"
   AWS_REGION="ap-southeast-1"
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
   ```bash
   aws configure
   # Masukkan AWS Access Key ID
   # Masukkan AWS Secret Access Key
   # Masukkan default region
   ```

   #### Google Drive
   ```bash
   rclone config
   # Ikuti petunjuk untuk mengkonfigurasi Google Drive
   ```

   #### Dropbox
   ```bash
   # Edit file dropbox_uploader.sh
   # Masukkan Dropbox API token
   ```

   #### Backblaze B2
   ```bash
   b2 authorize-account
   # Masukkan account ID dan application key
   ```

4. Berikan izin eksekusi pada script:
   ```bash
   chmod +x mysql_backup.sh
   ```

5. Jalankan script secara manual untuk testing:
   ```bash
   ./mysql_backup.sh
   ```
   Anda akan menerima notifikasi Telegram tentang status backup dan file backup (jika diaktifkan).

## Otomatisasi

Untuk menjalankan backup secara otomatis, gunakan crontab:

1. Buka crontab editor:
   ```bash
   crontab -e
   ```

2. Tambahkan baris berikut untuk menjalankan backup setiap hari jam 2 pagi:
   ```bash
   0 2 * * * /path/to/mysql_backup.sh
   ```

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
   File: /var/backups/mysql/your_database_20240220_020000.7z
   Ukuran: 1.2 GB
   ```

3. Upload ke cloud berhasil:
   ```
   ✅ Backup berhasil diupload ke AWS S3
   Lokasi: s3://your-bucket/mysql_backups/your_database_20240220_020000.7z
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
   - Periksa path ke 7z

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

5. **Error File Upload ke Telegram**:
   - Periksa ukuran file (maksimal 50MB)
   - Pastikan koneksi internet stabil
   - Periksa izin bot untuk mengirim file
   - Coba kompresi file jika terlalu besar 