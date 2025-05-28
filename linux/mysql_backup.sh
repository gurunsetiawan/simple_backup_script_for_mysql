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
DB_USER="your_mysql_username"        # Nama pengguna MySQL Anda
DB_PASS="your_mysql_password"        # Kata sandi pengguna MySQL Anda
DB_NAME="ALL_DATABASES"             # Gunakan "ALL_DATABASES" untuk backup semua database
                                    # Atau daftar database yang dipisahkan koma (misal: "db1,db2,db3")

# --- KONFIGURASI TELEGRAM ---
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
ENABLE_TELEGRAM_FILE=false  # Default: false, set ke true jika ingin mengirim file ke Telegram
TELEGRAM_FILE_SIZE_LIMIT=50  # Ukuran maksimal file dalam MB (default: 50MB)

# --- KONFIGURASI DIREKTORI & PATH APLIKASI ---
# Direktori tempat file backup akan disimpan.
BACKUP_DIR="/var/backups/mysql"      # Contoh: /var/backups/mysql

# --- KONFIGURASI RETENSI (OPSIONAL) ---
# Jumlah hari untuk menyimpan file backup. File yang lebih lama akan dihapus.
# Set ke 0 atau komentar baris ini jika tidak ingin menghapus backup lama.
RETENTION_DAYS=7                     # Contoh: 7 hari

# --- KONFIGURASI CLOUD STORAGE ---
# Set ke "true" untuk mengaktifkan upload ke cloud
ENABLE_CLOUD_BACKUP=true

# Pilih provider cloud (aws_s3, google_drive, dropbox, backblaze_b2)
CLOUD_PROVIDER="google_drive"

# Konfigurasi AWS S3
AWS_BUCKET="your-bucket-name"
AWS_REGION="ap-southeast-1"  # Sesuaikan dengan region Anda

# Konfigurasi Google Drive
RCLONE_REMOTE="gdrive"  # Nama remote rclone yang dikonfigurasi

# --- KONFIGURASI LOGGING ---
# Set ke "true" untuk mengaktifkan logging
ENABLE_LOGGING=true

# Direktori untuk menyimpan log file
LOG_DIR="/var/log/mysql_backup"

# Rotasi log setiap 3 bulan (90 hari)
LOG_RETENTION_DAYS=90

# Level log yang akan dicatat (DEBUG, INFO, WARNING, ERROR, CRITICAL)
LOG_LEVEL="INFO"

# Nama file log dengan format tanggal
LOG_FILE="${LOG_DIR}/mysql_backup_$(date +%Y%m%d).log"

# --- FUNGSI UNTUK LOGGING ---
log_message() {
    local level="$1"
    local message="$2"
    local details="$3"
    
    # Cek level log
    case "$LOG_LEVEL" in
        "DEBUG")
            ;;
        "INFO")
            if [ "$level" = "DEBUG" ]; then return; fi
            ;;
        "WARNING")
            if [ "$level" = "DEBUG" ] || [ "$level" = "INFO" ]; then return; fi
            ;;
        "ERROR")
            if [ "$level" = "DEBUG" ] || [ "$level" = "INFO" ] || [ "$level" = "WARNING" ]; then return; fi
            ;;
        "CRITICAL")
            if [ "$level" != "CRITICAL" ]; then return; fi
            ;;
    esac
    
    # Buat JSON log entry
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local json_log="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"details\":\"$details\"}"
    
    if [ "$ENABLE_LOGGING" = "true" ]; then
        echo "$json_log" >> "$LOG_FILE"
    fi
    echo "$timestamp [$level] $message"
}

# --- FUNGSI UNTUK ROTASI LOG ---
rotate_logs() {
    if [ "$ENABLE_LOGGING" = "true" ] && [ "$LOG_RETENTION_DAYS" -gt 0 ]; then
        log_message "INFO" "Menghapus log yang lebih lama dari $LOG_RETENTION_DAYS hari..." ""
        
        # Kompres log lama
        find "$LOG_DIR" -name "*.log" -type f -mtime +1 | while read -r log_file; do
            if [ -f "$log_file" ]; then
                gzip -9 "$log_file"
            fi
        done
        
        # Hapus log zip yang lebih lama dari retention period
        find "$LOG_DIR" -name "*.log.gz" -type f -mtime +$LOG_RETENTION_DAYS -delete
        
        if [ $? -eq 0 ]; then
            log_message "INFO" "Pembersihan log lama selesai." ""
        else
            log_message "WARNING" "Gagal membersihkan log lama. Periksa izin atau path." ""
        fi
    elif [ "$ENABLE_LOGGING" = "true" ]; then
        log_message "INFO" "Rotasi log dinonaktifkan (LOG_RETENTION_DAYS = 0)." ""
    fi
}

# --- FUNGSI UNTUK KIRIM NOTIFIKASI TELEGRAM ---
send_telegram_notification() {
    local status="$1"
    local message="$2"
    
    # Buat pesan lengkap
    local full_message="🔔 MySQL Backup Notification

📊 Status: $status
⏰ Time: $(date '+%Y-%m-%d %H:%M:%S')
📁 Database: $DB_NAME

$message"
    
    # Kirim notifikasi menggunakan curl
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${full_message}" \
        -d "parse_mode=HTML" >> "$LOG_FILE" 2>&1
}

# --- FUNGSI UNTUK BACKUP DATABASE ---
backup_database() {
    local db_name="$1"
    log_message "INFO" "Memulai backup database '$db_name'..." ""
    
    # Pastikan direktori backup ada
    mkdir -p "$BACKUP_DIR"
    
    # Buat timestamp untuk nama file
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${db_name}_${TIMESTAMP}.sql"
    FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
    
    # Backup database
    mysqldump -u "$DB_USER" -p"$DB_PASS" "$db_name" > "$FULL_BACKUP_PATH"
    
    # Cek apakah perintah mysqldump berhasil
    if [ $? -eq 0 ]; then
        log_message "INFO" "Backup database berhasil dibuat" "file=$FULL_BACKUP_PATH"
        return 0
    else
        log_message "ERROR" "Backup database gagal" "database=$db_name"
        return 1
    fi
}

# --- FUNGSI UNTUK BACKUP MULTIPLE DATABASES ---
backup_multiple_databases() {
    log_message "INFO" "Memulai backup multiple databases..." ""
    
    # Buat timestamp untuk nama file
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ARCHIVE_FILE="mysql_backup_${TIMESTAMP}.7z"
    FULL_ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_FILE}"
    
    # Backup setiap database
    local success=true
    if [ "$DB_NAME" = "ALL_DATABASES" ]; then
        # Dapatkan daftar semua database
        databases=$(mysql -u "$DB_USER" -p"$DB_PASS" -N -e "SHOW DATABASES" | grep -v "information_schema\|performance_schema\|mysql\|sys")
        for db in $databases; do
            backup_database "$db"
            if [ $? -ne 0 ]; then
                success=false
            fi
        done
    else
        # Backup database yang ditentukan
        IFS=',' read -ra DB_ARRAY <<< "$DB_NAME"
        for db in "${DB_ARRAY[@]}"; do
            backup_database "$db"
            if [ $? -ne 0 ]; then
                success=false
            fi
        done
    fi
    
    # Kompres semua file SQL ke satu archive
    if [ "$success" = true ]; then
        7z a -t7z -m0=lzma2 -mx=9 "$FULL_ARCHIVE_PATH" "${BACKUP_DIR}/*_${TIMESTAMP}.sql"
        if [ $? -eq 0 ]; then
            log_message "INFO" "Kompresi berhasil" "archive=$FULL_ARCHIVE_PATH"
            # Hapus file SQL individual
            # rm "${BACKUP_DIR}/*_${TIMESTAMP}.sql" # Penghapusan dipindahkan ke bawah
            # log_message "INFO" "File SQL individual telah dihapus" "" # Penghapusan dipindahkan ke bawah
            return 0 # Kompresi berhasil
        else
            log_message "ERROR" "Kompresi gagal" ""
            # Lanjutkan eksekusi untuk menghapus file .sql meskipun kompresi gagal
            return 1 # Kompresi gagal
        fi
    else
        log_message "ERROR" "Beberapa database gagal dibackup" ""
        # Lanjutkan eksekusi untuk menghapus file .sql meskipun backup gagal
        return 1 # Backup database gagal
    fi
    
    # --- LANGKAH PEMBERSIHAN FILE .SQL ---    
    # Hapus file .sql individual dengan timestamp saat ini
    # Langkah ini dijalankan terlepas dari keberhasilan kompresi
    if ls "${BACKUP_DIR}/*_${TIMESTAMP}.sql" 1> /dev/null 2>&1; then
        rm "${BACKUP_DIR}/*_${TIMESTAMP}.sql"
        if [ $? -eq 0 ]; then
            log_message "INFO" "File SQL individual dengan timestamp $TIMESTAMP telah dihapus." ""
        else
            log_message "WARNING" "Gagal menghapus file SQL individual dengan timestamp $TIMESTAMP." ""
        fi
    else
        #log_message "DEBUG" "Tidak ada file SQL individual dengan timestamp $TIMESTAMP ditemukan untuk dihapus." ""
        : # Tidak melakukan apa-apa jika tidak ada file yang cocok ditemukan
    fi
    # --- AKHIR LANGKAH PEMBERSIHAN ---
}

# --- FUNGSI UNTUK ROTASI BACKUP ---
clean_old_backups() {
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        log_message "INFO" "Menghapus backup yang lebih lama dari $RETENTION_DAYS hari..." ""
        find "$BACKUP_DIR" -name "*.7z" -type f -mtime +$RETENTION_DAYS -delete
        if [ $? -eq 0 ]; then
            log_message "INFO" "Pembersihan backup lama selesai." ""
        else
            log_message "WARNING" "Gagal membersihkan backup lama. Periksa izin atau path." ""
        fi
    else
        log_message "INFO" "Rotasi backup dinonaktifkan (RETENTION_DAYS = 0)." ""
    fi
}

# --- FUNGSI UNTUK UPLOAD KE CLOUD ---
upload_to_cloud() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    
    if [ "$ENABLE_CLOUD_BACKUP" = "true" ]; then
        log_message "INFO" "Memulai upload ke cloud storage..." ""
        
        case "$CLOUD_PROVIDER" in
            "aws_s3")
                # Upload ke AWS S3
                aws s3 cp "$file_path" "s3://${AWS_BUCKET}/mysql_backups/${file_name}" \
                    --region "$AWS_REGION" \
                    --storage-class STANDARD_IA  # Menggunakan storage class yang lebih murah
                
                if [ $? -eq 0 ]; then
                    log_message "INFO" "Upload ke AWS S3 berhasil" ""
                    send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke AWS S3"
                    return 0
                else
                    log_message "ERROR" "Upload ke AWS S3 gagal" ""
                    send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke AWS S3"
                    return 1
                fi
                ;;
                
            "google_drive")
                # Upload ke Google Drive menggunakan rclone
                rclone copy "$file_path" "${RCLONE_REMOTE}:mysql_backups/"
                
                if [ $? -eq 0 ]; then
                    log_message "INFO" "Upload ke Google Drive berhasil" ""
                    send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke Google Drive"
                    return 0
                else
                    log_message "ERROR" "Upload ke Google Drive gagal" ""
                    send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke Google Drive"
                    return 1
                fi
                ;;
                
            "dropbox")
                # Upload ke Dropbox
                ./dropbox_uploader.sh upload "$file_path" "/mysql_backups/"
                
                if [ $? -eq 0 ]; then
                    log_message "INFO" "Upload ke Dropbox berhasil" ""
                    send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke Dropbox"
                    return 0
                else
                    log_message "ERROR" "Upload ke Dropbox gagal" ""
                    send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke Dropbox"
                    return 1
                fi
                ;;
                
            "backblaze_b2")
                # Upload ke Backblaze B2
                b2 upload-file "$AWS_BUCKET" "$file_path" "mysql_backups/${file_name}"
                
                if [ $? -eq 0 ]; then
                    log_message "INFO" "Upload ke Backblaze B2 berhasil" ""
                    send_telegram_notification "CLOUD_SUCCESS" "✅ Backup berhasil diupload ke Backblaze B2"
                    return 0
                else
                    log_message "ERROR" "Upload ke Backblaze B2 gagal" ""
                    send_telegram_notification "CLOUD_ERROR" "❌ Gagal mengupload backup ke Backblaze B2"
                    return 1
                fi
                ;;
                
            *)
                log_message "ERROR" "Provider cloud tidak dikenali" ""
                return 1
                ;;
        esac
    else
        log_message "INFO" "Cloud backup dinonaktifkan" ""
        return 0
    fi
}

# ==============================================================================
# --- JALANKAN PROSES BACKUP ---
# ==============================================================================
# Buat direktori log jika belum ada
if [ "$ENABLE_LOGGING" = "true" ]; then
    mkdir -p "$LOG_DIR"
    rotate_logs
fi

log_message "INFO" "----------------------------------------------------" ""
log_message "INFO" "Memulai proses backup MySQL..." ""

# Kirim notifikasi mulai backup
send_telegram_notification "STARTED" "Memulai proses backup database..."

# Panggil fungsi backup database
backup_multiple_databases

if [ $? -eq 0 ]; then
    log_message "INFO" "Proses backup dan kompresi selesai dengan sukses." ""
    send_telegram_notification "SUCCESS" "✅ Backup dan kompresi selesai dengan sukses."
    
    # Upload ke cloud storage
    upload_to_cloud "$FULL_ARCHIVE_PATH"
    
    clean_old_backups
else
    log_message "ERROR" "Proses backup selesai dengan ERROR." ""
    send_telegram_notification "ERROR" "❌ Gagal pada proses backup database."
fi

log_message "INFO" "----------------------------------------------------" "" 