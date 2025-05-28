# MySQL Backup Script for Linux

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
2. p7zip-full untuk kompresi
3. curl untuk notifikasi Telegram
4. Cloud storage tools (pilih salah satu):
   - AWS CLI untuk AWS S3
   - rclone untuk Google Drive
   - Dropbox Uploader untuk Dropbox
   - B2 CLI untuk Backblaze B2

### Instalasi Dependensi

#### Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install mysql-client p7zip-full curl

# Untuk AWS S3
pip install awscli

# Untuk Google Drive
curl https://rclone.org/install.sh | sudo bash

# Untuk Dropbox
wget https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh
chmod +x dropbox_uploader.sh

# Untuk Backblaze B2
pip install b2
```

#### CentOS/RHEL:
```bash
sudo yum install mysql p7zip p7zip-plugins curl

# Untuk AWS S3
pip install awscli

# Untuk Google Drive
curl https://rclone.org/install.sh | sudo bash

# Untuk Dropbox
wget https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh
chmod +x dropbox_uploader.sh

# Untuk Backblaze B2
pip install b2
```

## Konfigurasi Cepat

1. Edit file `mysql_backup.sh` dan sesuaikan konfigurasi berikut:

   ```bash
   # Konfigurasi Database
   MYSQL_USER="your_username"
   MYSQL_PASSWORD="your_password"
   MYSQL_DATABASE="your_database"  # Atau "all" untuk backup semua database
   
   # Konfigurasi Telegram
   TELEGRAM_BOT_TOKEN="your_bot_token"
   TELEGRAM_CHAT_ID="your_chat_id"
   
   # Konfigurasi Cloud Storage
   ENABLE_CLOUD_BACKUP=true
   CLOUD_PROVIDER="aws_s3"  # Pilih: aws_s3, google_drive, dropbox, backblaze_b2
   
   # Konfigurasi AWS S3
   AWS_BUCKET="your-bucket-name"
   AWS_REGION="ap-southeast-1"
   ```

2. Konfigurasi Cloud Storage:

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
   ./dropbox_uploader.sh
   # Masukkan Dropbox API token
   ```

   #### Backblaze B2
   ```bash
   b2 authorize-account
   # Masukkan account ID dan application key
   ```

3. Berikan izin eksekusi pada script:
   ```bash
   chmod +x mysql_backup.sh
   ```

4. Jalankan script secara manual untuk testing:
   ```bash
   ./mysql_backup.sh
   ```
   Anda akan menerima notifikasi Telegram tentang status backup.

## Otomatisasi

Untuk menjalankan backup secara otomatis, tambahkan ke crontab:

```bash
# Edit crontab
crontab -e

# Tambahkan baris berikut untuk menjalankan backup setiap hari jam 2 pagi
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
   - Pertimbangkan untuk menggunakan mount point terpisah

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
   - Pastikan p7zip terinstal dengan benar

3. **Error Telegram**:
   - Periksa token bot dan chat ID
   - Pastikan bot sudah diaktifkan
   - Periksa koneksi internet

4. **Error Cloud Storage**:
   - Periksa kredensial cloud storage
   - Pastikan bucket/folder sudah dibuat
   - Periksa permission dan policy
   - Verifikasi koneksi internet 