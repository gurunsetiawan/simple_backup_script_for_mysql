# MySQL Backup Script for Windows

Script ini menyediakan cara mudah untuk melakukan backup otomatis database MySQL ke dalam format 7z, termasuk pembersihan backup lama dan notifikasi Telegram.

## 🚀 Fitur

- Backup Otomatis: Menggunakan mysqldump untuk membuat backup database
- Kompresi Efisien: Mengkompresi backup ke format 7z untuk menghemat ruang
- Penamaan Berdasarkan Tanggal: Backup diberi nama dengan format YYYY-MM-DD_HH-MM-SS
- Cakupan Fleksibel: Backup satu database atau semua database
- Pembersihan Otomatis: Menghapus backup lama secara otomatis
- Notifikasi Telegram: Notifikasi real-time tentang status backup

## 🛠️ Persyaratan

- MySQL Server: `mysqldump.exe` (biasanya sudah termasuk dalam instalasi MySQL)
- 7-Zip: `7z.exe` command-line tool
  - Download dari [7-Zip website](https://7-zip.org/)
  - Pastikan path ke `7z.exe` sudah benar dalam script
- PowerShell: Untuk mengirim notifikasi Telegram (sudah termasuk dalam Windows)

## ⚙️ Pengaturan Cepat

1. Konfigurasi Script
   Buka script dalam editor teks dan sesuaikan variabel berikut:
   ```batch
   SET DB_USER=your_mysql_username        REM Nama pengguna MySQL Anda
   SET DB_PASS=your_mysql_password        REM Kata sandi pengguna MySQL Anda
   SET DB_NAME=your_database_name         REM Nama database atau "ALL_DATABASES"
   SET BACKUP_DIR=C:\MySQL_Backups        REM Direktori backup
   SET RETENTION_DAYS=7                   REM Jumlah hari untuk menyimpan backup
   ```

2. Konfigurasi Path Aplikasi
   Sesuaikan path ke aplikasi yang diperlukan:
   ```batch
   SET MYSQLDUMP_PATH="C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe"
   SET PATH_7Z="C:\Program Files\7-Zip\7z.exe"
   ```

3. Konfigurasi Notifikasi Telegram
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
      ```batch
      SET TELEGRAM_BOT_TOKEN=your_bot_token_here
      SET TELEGRAM_CHAT_ID=your_chat_id_here
      ```

4. Test Manual
   ```batch
   cd C:\path\to\script\directory
   mysql_backup.bat
   ```
   Anda akan menerima notifikasi Telegram tentang status backup.

5. Jadwalkan Otomatisasi
   a. Buka Task Scheduler:
      - Cari "Task Scheduler" di Start Menu
      - Klik "Create Basic Task..."

   b. Konfigurasi Task:
      - Name: "Daily MySQL Backup"
      - Trigger: "Daily" at 2:00 AM
      - Action: "Start a program"
      - Program: Browse ke file `mysql_backup.bat`
      - Start in: Masukkan direktori tempat `mysql_backup.bat` berada

   c. Setelah pembuatan task:
      - Klik kanan pada task
      - Pilih Properties
      - Centang "Run with highest privileges"
      - Opsional: Centang "Run whether user is logged on or not"

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
  - Pastikan file script hanya bisa diakses oleh pengguna yang berwenang
  - Untuk production, pertimbangkan menggunakan environment variables
  - Jaga kerahasiaan token bot Telegram

- Lokasi Backup:
  - Idealnya simpan backup di disk berbeda atau off-site
  - Pertimbangkan cloud storage untuk keamanan tambahan
  - Pastikan direktori backup memiliki permission yang tepat

- Testing:
  - Test Restore! Backup hanya berguna jika bisa di-restore
  - Test proses recovery secara berkala
  - Verifikasi notifikasi Telegram berfungsi

- Monitoring:
  - Periksa Task Scheduler history secara berkala
  - Monitor notifikasi Telegram
  - Verifikasi file backup dibuat dan dirotasi dengan benar

## 🔧 Troubleshooting

1. Script tidak berjalan:
   - Pastikan path ke `mysqldump.exe` dan `7z.exe` sudah benar
   - Pastikan user memiliki akses ke direktori backup
   - Jalankan script sebagai Administrator

2. Notifikasi Telegram tidak terkirim:
   - Periksa koneksi internet
   - Verifikasi token bot dan chat ID
   - Pastikan PowerShell bisa mengakses internet

3. Backup gagal:
   - Periksa kredensial database
   - Pastikan MySQL server berjalan
   - Periksa ruang disk yang tersedia
