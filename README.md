# MySQL Backup Script

Script otomatisasi backup database MySQL dengan fitur kompresi 7z dan notifikasi Telegram.

## 📁 Struktur Proyek

```
.
├── windows/                 # Versi Windows
│   ├── mysql_backup.bat    # Script backup untuk Windows
│   └── README.md           # Dokumentasi versi Windows
│
└── linux/                  # Versi Linux
    ├── mysql_backup.sh     # Script backup untuk Linux
    └── README.md           # Dokumentasi versi Linux
```

## 🚀 Fitur Utama

- Backup otomatis database MySQL
- Kompresi ke format 7z untuk menghemat ruang
- Penamaan file berdasarkan timestamp
- Pembersihan backup lama secara otomatis
- Notifikasi real-time via Telegram
- Mendukung backup single database atau all databases

## ⚙️ Memilih Versi yang Tepat

### Windows
- Gunakan folder `windows/` jika Anda menggunakan sistem operasi Windows
- Script menggunakan PowerShell untuk notifikasi Telegram
- Menggunakan Task Scheduler untuk otomatisasi

### Linux
- Gunakan folder `linux/` jika Anda menggunakan sistem operasi Linux
- Script menggunakan curl untuk notifikasi Telegram
- Menggunakan crontab untuk otomatisasi

## 📚 Dokumentasi

- Untuk Windows: Lihat [README.md di folder windows](windows/README.md)
- Untuk Linux: Lihat [README.md di folder linux](linux/README.md)

## 🔒 Keamanan

- Jaga kerahasiaan kredensial database
- Amankan token bot Telegram
- Gunakan permission yang tepat untuk file script
- Pertimbangkan menggunakan metode yang lebih aman untuk menyimpan kredensial

## 🤝 Kontribusi

Silakan buat pull request untuk kontribusi. Untuk perubahan besar, buka issue terlebih dahulu untuk mendiskusikan perubahan yang diinginkan.

## 📝 Lisensi

Lihat file [LICENSE](LICENSE) untuk detail lisensi. 