# MySQL Backup Script for Linux

Script ini menyediakan cara mudah untuk melakukan backup otomatis database MySQL ke dalam format 7z, termasuk pembersihan backup lama dan notifikasi Telegram.

## 🚀 Fitur

- Backup Otomatis: Menggunakan mysqldump untuk membuat backup database
- Kompresi Efisien: Mengkompresi backup ke format 7z untuk menghemat ruang
- Penamaan Berdasarkan Tanggal: Backup diberi nama dengan format YYYY-MM-DD_HH-MM-SS
- Cakupan Fleksibel: Backup satu database atau semua database
- Pembersihan Otomatis: Menghapus backup lama secara otomatis
- Notifikasi Telegram: Notifikasi real-time tentang status backup

## 🛠️ Persyaratan

- MySQL Server: Tool mysqldump (biasanya sudah termasuk dalam instalasi MySQL)
- 7-Zip: Package p7zip-full
  ```bash
  # Debian/Ubuntu
  sudo apt-get install p7zip-full

  # CentOS/RHEL
  sudo yum install p7zip p7zip-plugins
  ```
- curl: Untuk mengirim notifikasi Telegram
  ```bash
  # Debian/Ubuntu
  sudo apt-get install curl

  # CentOS/RHEL
  sudo yum install curl
  ```

## ⚙️ Pengaturan Cepat

1. Konfigurasi Script
   Buka script dalam editor teks dan sesuaikan variabel berikut:
   ```bash
   DB_USER="your_mysql_username"        # Username MySQL Anda
   DB_PASS="your_mysql_password"        # Password MySQL Anda
   DB_NAME="your_database_name"         # Nama database atau "ALL_DATABASES"
   BACKUP_DIR="/var/backups/mysql"      # Direktori backup
   RETENTION_DAYS=7                     # Jumlah hari untuk menyimpan backup
   ```

2. Konfigurasi Notifikasi Telegram
   a. Buat Bot Telegram:
      - Buka Telegram dan cari "@BotFather"
      - Kirim perintah `/newbot`
      - Ikuti instruksi untuk membuat bot baru
      - Simpan BOT_TOKEN yang diberikan

   b. Dapatkan Chat ID:
      - Kirim pesan ke bot baru Anda
      - Buka browser dan akses: `https://api.telegram.org/bot<BOT_TOKEN>/getUpdates`
      - Cari `"chat":{"id":` dalam response

   c. Update Konfigurasi Script:
      ```bash
      TELEGRAM_BOT_TOKEN="your_bot_token_here"
      TELEGRAM_CHAT_ID="your_chat_id_here"
      ```

3. Test Manual
   ```bash
   # Berikan izin eksekusi
   chmod +x mysql_backup.sh

   # Jalankan script
   ./mysql_backup.sh
   ```
   Anda akan menerima notifikasi Telegram tentang status backup.

4. Jadwalkan Otomatisasi
   Buka crontab:
   ```bash
   crontab -e
   ```
   Tambahkan baris berikut untuk menjalankan backup setiap hari jam 2 pagi:
   ```
   0 2 * * * /path/to/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1
   ```

## 📱 Notifikasi Telegram

Script mengirim notifikasi pada beberapa tahap penting:

1. Mulai Backup:
```
🔔 MySQL Backup Notification

📊 Status: STARTED
⏰ Time: [Waktu Backup]
📁 Database: [Nama Database]

Memulai proses backup database...
```

2. Backup Sukses:
```
🔔 MySQL Backup Notification

📊 Status: SUCCESS
⏰ Time: [Waktu Backup]
📁 Database: [Nama Database]

✅ Backup dan kompresi selesai dengan sukses.
```

3. Backup Error:
```
🔔 MySQL Backup Notification

📊 Status: ERROR
⏰ Time: [Waktu Backup]
📁 Database: [Nama Database]

❌ [Pesan Error]
```

## 💡 Catatan Penting

- Keamanan:
  - Menyimpan password dalam script memiliki risiko
  - Pastikan permission file script aman (chmod 600)
  - Untuk production, pertimbangkan menggunakan .my.cnf atau environment variables
  - Jaga kerahasiaan token bot Telegram

- Lokasi Backup:
  - Idealnya simpan backup di disk berbeda atau off-site
  - Pertimbangkan cloud storage untuk keamanan tambahan

- Testing:
  - Test Restore! Backup hanya berguna jika bisa di-restore
  - Test proses recovery secara berkala
  - Verifikasi notifikasi Telegram berfungsi

- Monitoring:
  - Periksa log secara berkala (/var/log/mysql_backup.log)
  - Monitor notifikasi Telegram
  - Verifikasi file backup dibuat dan dirotasi dengan benar 