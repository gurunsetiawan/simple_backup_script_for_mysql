# README: Automated MySQL Database Backup #

This guide provides a quick and easy way to set up automated MySQL database backups to a 7z archive, including automatic old backup cleanup and Telegram notifications.

### 🚀 Features ###

Automated Backups: Uses mysqldump to create full database backups.
Efficient Compression: Compresses backups to .7z format to save disk space.
Date-Based Naming: Backups are named with a YYYY-MM-DD_HH-MM-SS timestamp for easy identification.
Flexible Scope: Back up a single database or all databases on your server.
Automatic Cleanup: Automatically deletes old backups to manage storage.
Telegram Notifications: Real-time notifications about backup status via Telegram.


### 🛠️ Requirements ###

For Linux/macOS (Bash Script)

MySQL Server: mysqldump tool (usually included with MySQL server installation).
7-Zip: p7zip-full package. Install with sudo apt-get install p7zip-full (Debian/Ubuntu) or sudo yum install p7zip p7zip-plugins (CentOS/RHEL).

For Windows (Batch Script)

MySQL Server: `mysqldump.exe` (included with MySQL server installation).
7-Zip: `7z.exe` command-line tool. Ensure it's installed and its path is known.
PowerShell: Required for Telegram notifications (included in Windows by default).

### ⚙️ Quick Setup & Usage ###

1. Configure Your Script
Choose the script for your OS: backup_mysql.sh (Linux/macOS) or backup_mysql.bat (Windows).

Open the script in any text editor.

Adjust these variables:
```
DB_USER: Your MySQL username.
DB_PASS: Your MySQL password.
DB_NAME: The database to backup (e.g., "my_app_db"). Use "ALL_DATABASES" to back up all databases.
```
BACKUP_DIR: The full path to your backup directory (e.g., `/var/backups/mysql` or `C:\MySQL_Backups`). Ensure this directory exists and has write permissions.


RETENTION_DAYS: How many days to keep backups (e.g., 7 for a week). Set to 0 to disable auto-cleanup.

Windows only:
```
MYSQLDUMP_PATH: Full path to mysqldump.exe (e.g., "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe").
PATH_7Z: Full path to 7z.exe (e.g., "C:\Program Files\7-Zip\7z.exe").
```
2. Configure Telegram Notifications
To enable Telegram notifications:

a. Create a Telegram Bot:
   - Open Telegram and search for "@BotFather"
   - Send `/newbot` command
   - Follow instructions to create a new bot
   - Save the BOT_TOKEN provided

b. Get Your Chat ID:
   - Send a message to your new bot
   - Open browser and visit: `https://api.telegram.org/bot<BOT_TOKEN>/getUpdates`
   - Look for `"chat":{"id":` in the response

c. Update Script Configuration:
   - Set `TELEGRAM_BOT_TOKEN` with your bot token
   - Set `TELEGRAM_CHAT_ID` with your chat ID

2. Test Manually

Run the script once to confirm everything works as expected:

Linux/macOS:
```Bash

chmod +x /path/to/your/backup_mysql.sh
/path/to/your/backup_mysql.sh
```

Windows:
```DOS

cd C:\path\to\your\script\directory
backup_mysql.bat
```
You should receive a Telegram notification with the backup status.

3. Schedule Automation
Linux/macOS (Cron):
Open crontab: `crontab -e`
Add a line like this to run daily at 2 AM:

```
0 2 * * * /path/to/your/backup_mysql.sh >> /var/log/mysql_backup.log 2>&1
```
Replace /path/to/your/backup_mysql.sh with your script's actual path. Output will be logged to `/var/log/mysql_backup.log`.

Windows (Task Scheduler):

Search for `"Task Scheduler"` in the Start Menu.
Click `"Create Basic Task..."`.
Follow the wizard: Give it a Name (e.g., "Daily MySQL Backup"), set the Trigger (e.g., "Daily" at 2:00 AM).
For Action, choose "Start a program". Browse to your backup_mysql.bat file.
In "Start in (optional)", enter the directory where backup_mysql.bat is located (e.g., C:\Scripts\).
After creation, right-click the task, select Properties, check "Run with highest privileges", and optionally select "Run whether user is logged on or not" (you'll need to provide Windows user credentials).


### 📱 Telegram Notifications ###

The script sends notifications at key points during the backup process:

1. Backup Start:
```
🔔 MySQL Backup Notification

📊 Status: STARTED
⏰ Time: [Current Time]
📁 Database: [Database Name]

Memulai proses backup database...
```

2. Backup Success:
```
🔔 MySQL Backup Notification

📊 Status: SUCCESS
⏰ Time: [Current Time]
📁 Database: [Database Name]

✅ Backup dan kompresi selesai dengan sukses.
```

3. Backup Error:
```
🔔 MySQL Backup Notification

📊 Status: ERROR
⏰ Time: [Current Time]
📁 Database: [Database Name]

❌ [Error Message]
```

### 💡 Important Notes ###

Security: Storing passwords directly in scripts carries a risk. Ensure strict file permissions for your script. For production, consider more secure methods like MySQL's .my.cnf file (Linux) or environment variables.
Backup Location: Ideally, store backups on a different disk or even off-site (e.g., cloud storage) to protect against data loss from hardware failure.

Test Restores! A backup is only useful if you can restore it. Regularly test your recovery process to ensure your backups are valid and usable.

Monitor Logs: Periodically check the logs `(/var/log/mysql_backup.log or Task Scheduler history)` to confirm successful backups and identify any issues.

Verify Telegram notifications are working.
