#!/bin/bash

# ==============================================================================
# Script Otomatisasi Backup Database MySQL
# Deskripsi: Melakukan backup database MySQL menggunakan mysqldump,
#            kemudian mengkompresinya ke dalam format 7z dengan penamaan
#            berdasarkan tanggal, bulan, dan tahun.
#            Juga menyertakan fitur untuk menghapus backup lama.
# ==============================================================================

# --- KONFIGURASI DATABASE ---
# Ganti nilai-nilai berikut dengan kredensial database Anda.
# Jika ingin membackup semua database, set DB_NAME="ALL_DATABASES"
DB_USER="your_mysql_username"        # Nama pengguna MySQL Anda
DB_PASS="your_mysql_password"        # Kata sandi pengguna MySQL Anda
DB_NAME="your_database_name"         # Nama database yang akan dibackup (misal: "my_app_db")
                                    # Atau gunakan "ALL_DATABASES" untuk backup semua database

# --- KONFIGURASI TELEGRAM ---
TELEGRAM_BOT_TOKEN="your_bot_token_here"    # Token bot Telegram Anda
TELEGRAM_CHAT_ID="your_chat_id_here"        # Chat ID untuk notifikasi

# --- KONFIGURASI DIREKTORI & PATH APLIKASI ---
# Direktori tempat file backup akan disimpan.
BACKUP_DIR="/var/backups/mysql"      # Contoh: /var/backups/mysql

# --- KONFIGURASI RETENSI (OPSIONAL) ---
# Jumlah hari untuk menyimpan file backup. File yang lebih lama akan dihapus.
# Set ke 0 atau komentar baris ini jika tidak ingin menghapus backup lama.
RETENTION_DAYS=7                     # Contoh: 7 hari

# --- FUNGSI UNTUK LOGGING ---
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# --- FUNGSI UNTUK KIRIM NOTIFIKASI TELEGRAM ---
send_telegram_notification() {
    local status="$1"
    local message="$2"
    local full_message="🔔 MySQL Backup Notification

📊 Status: $status
⏰ Time: $(date '+%Y-%m-%d %H:%M:%S')
📁 Database: $DB_NAME

$message"

    # URL encode pesan
    local encoded_message=$(echo "$full_message" | sed 's/ /%20/g')
    
    # Kirim notifikasi menggunakan curl
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=HTML" > /dev/null 2>&1
}

# --- FUNGSI UNTUK BACKUP DATABASE ---
backup_database() {
    log_message "Memulai backup database '$DB_NAME'..."

    # Pastikan direktori backup ada
    mkdir -p "$BACKUP_DIR"

    # Buat timestamp untuk nama file
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    BACKUP_FILE="${DB_NAME}_${TIMESTAMP}.sql"
    FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

    if [ "$DB_NAME" = "ALL_DATABASES" ]; then
        # Backup semua database
        mysqldump -u "$DB_USER" -p"$DB_PASS" --all-databases > "$FULL_BACKUP_PATH"
    else
        # Backup satu database spesifik
        mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$FULL_BACKUP_PATH"
    fi

    # Cek apakah perintah mysqldump berhasil
    if [ $? -eq 0 ]; then
        log_message "Backup database berhasil dibuat: '$FULL_BACKUP_PATH'"
        return 0
    else
        log_message "ERROR: Backup database gagal!"
        return 1
    fi
}

# --- FUNGSI UNTUK KOMPRESI MENGGUNAKAN 7Z ---
compress_backup() {
    log_message "Memulai kompresi file backup..."

    # Nama file archive 7z
    ARCHIVE_FILE="${DB_NAME}_${TIMESTAMP}.7z"
    FULL_ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_FILE}"

    # Parameter kompresi 7z:
    # a      : Tambahkan ke arsip
    # -t7z   : Tipe arsip 7z
    # -m0=lzma2: Menggunakan algoritma kompresi LZMA2 (efisien)
    # -mx=9  : Tingkat kompresi maksimal (0=tanpa kompresi, 9=maksimal)
    7z a -t7z -m0=lzma2 -mx=9 "$FULL_ARCHIVE_PATH" "$FULL_BACKUP_PATH"

    # Cek apakah perintah 7z berhasil
    if [ $? -eq 0 ]; then
        log_message "Kompresi berhasil. File archive: '$FULL_ARCHIVE_PATH'"
        # Hapus file .sql asli setelah berhasil dikompresi untuk menghemat ruang
        rm "$FULL_BACKUP_PATH"
        log_message "File SQL asli ('$BACKUP_FILE') telah dihapus."
        return 0
    else
        log_message "ERROR: Kompresi gagal!"
        return 1
    fi
}

# --- FUNGSI UNTUK ROTASI BACKUP ---
clean_old_backups() {
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        log_message "Menghapus backup yang lebih lama dari $RETENTION_DAYS hari..."
        find "$BACKUP_DIR" -name "*.7z" -type f -mtime +$RETENTION_DAYS -delete
        if [ $? -eq 0 ]; then
            log_message "Pembersihan backup lama selesai."
        else
            log_message "PERINGATAN: Gagal membersihkan backup lama. Periksa izin atau path."
        fi
    else
        log_message "Rotasi backup dinonaktifkan (RETENTION_DAYS = 0)."
    fi
}

# ==============================================================================
# --- JALANKAN PROSES BACKUP ---
# ==============================================================================
log_message "----------------------------------------------------"
log_message "Memulai proses backup MySQL..."

# Kirim notifikasi mulai backup
send_telegram_notification "STARTED" "Memulai proses backup database..."

# Panggil fungsi backup database
if backup_database; then
    # Jika backup database berhasil, lanjutkan dengan kompresi
    if compress_backup; then
        log_message "Proses backup dan kompresi selesai dengan sukses."
        send_telegram_notification "SUCCESS" "✅ Backup dan kompresi selesai dengan sukses."
        clean_old_backups # Panggil fungsi pembersihan setelah backup baru dibuat
    else
        log_message "Proses backup selesai dengan ERROR pada kompresi."
        send_telegram_notification "ERROR" "❌ Gagal pada proses kompresi backup."
    fi
else
    log_message "Proses backup selesai dengan ERROR pada backup database."
    send_telegram_notification "ERROR" "❌ Gagal pada proses backup database."
fi

log_message "----------------------------------------------------" 