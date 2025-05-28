#!/bin/bash

# ==============================================================================
# Script Otomatisasi Backup Database MySQL
# Deskripsi: Melakukan backup database MySQL menggunakan mysqldump,
#            kemudian mengkompresinya ke dalam format 7z dengan penamaan
#            berdasarkan tanggal, bulan, dan tahun.
# ==============================================================================

# --- KONFIGURASI DATABASE ---
# Ganti nilai-nilai berikut dengan kredensial database Anda.
# Jika ingin membackup semua database, set DB_NAME="ALL_DATABASES"
DB_USER="your_mysql_username"        # Nama pengguna MySQL Anda
DB_PASS="your_mysql_password"        # Kata sandi pengguna MySQL Anda
DB_NAME="your_database_name"         # Nama database yang akan dibackup (misal: "my_app_db")
                                     # Atau gunakan "ALL_DATABASES" untuk backup semua database

# --- KONFIGURASI DIREKTORI ---
# Direktori tempat file backup akan disimpan.
# Pastikan direktori ini ada dan memiliki izin tulis yang sesuai.
BACKUP_DIR="/var/backups/mysql"      # Contoh: /home/user/mysql_backups atau /mnt/backups/mysql

# --- KONFIGURASI RETENSI (OPSIONAL) ---
# Jumlah hari untuk menyimpan file backup. File yang lebih lama akan dihapus.
# Set ke 0 atau komentar baris ini jika tidak ingin menghapus backup lama.
RETENTION_DAYS=7                     # Contoh: 7 hari

# --- VARIABEL PENAMAAN FILE ---
# Membuat timestamp unik untuk nama file backup.
# Format: YYYY-MM-DD_HH-MM-SS
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Nama file SQL sebelum dikompresi
BACKUP_FILE="${DB_NAME}_${TIMESTAMP}.sql"

# Nama file archive 7z
ARCHIVE_FILE="${DB_NAME}_${TIMESTAMP}.7z"

# Path lengkap untuk file SQL dan 7z
FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
FULL_ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_FILE}"

# --- FUNGSI UNTUK LOGGING ---
# Fungsi sederhana untuk mencetak pesan ke konsol dan log file.
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# --- FUNGSI UNTUK BACKUP DATABASE ---
backup_database() {
    log_message "Memulai backup database '$DB_NAME'..."

    # Pastikan direktori backup ada
    mkdir -p "$BACKUP_DIR"

    if [ "$DB_NAME" == "ALL_DATABASES" ]; then
        # Backup semua database
        mysqldump -u "$DB_USER" -p"$DB_PASS" --all-databases > "$FULL_BACKUP_PATH"
    else
        # Backup satu database spesifik
        mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$FULL_BACKUP_PATH"
    fi

    # Cek apakah perintah mysqldump berhasil
    if [ $? -eq 0 ]; then
        log_message "Backup database berhasil dibuat: '$FULL_BACKUP_PATH'"
        return 0 # Sukses
    else
        log_message "ERROR: Backup database gagal!"
        return 1 # Gagal
    fi
}

# --- FUNGSI UNTUK KOMPRESI MENGGUNAKAN 7Z ---
compress_backup() {
    log_message "Memulai kompresi file backup ke '$FULL_ARCHIVE_PATH'..."

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
        return 0 # Sukses
    else
        log_message "ERROR: Kompresi gagal!"
        return 1 # Gagal
    fi
}

# --- FUNGSI UNTUK ROTASI BACKUP ---
# Menghapus file backup 7z yang lebih lama dari RETENTION_DAYS
clean_old_backups() {
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        log_message "Menghapus backup yang lebih lama dari $RETENTION_DAYS hari..."
        # find: Mencari file
        # "$BACKUP_DIR": Di direktori ini
        # -type f: Hanya file
        # -name "*.7z": Dengan nama yang diakhiri .7z
        # -mtime +$RETENTION_DAYS: Dimodifikasi lebih dari $RETENTION_DAYS hari yang lalu
        # -delete: Hapus file yang ditemukan
        find "$BACKUP_DIR" -type f -name "*.7z" -mtime +$RETENTION_DAYS -delete

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

# Panggil fungsi backup database
if backup_database; then
    # Jika backup database berhasil, lanjutkan dengan kompresi
    if compress_backup; then
        log_message "Proses backup dan kompresi selesai dengan sukses."
        clean_old_backups # Panggil fungsi pembersihan setelah backup baru dibuat
    else
        log_message "Proses backup selesai dengan ERROR pada kompresi."
    fi
else
    log_message "Proses backup selesai dengan ERROR pada backup database."
fi

log_message "----------------------------------------------------"
