# Backup and Recovery Guide

Comprehensive guide for implementing backup strategies and disaster recovery procedures for the Hosting Management Platform.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Backup Strategy](#backup-strategy)
4. [Database Backups](#database-backups)
5. [File System Backups](#file-system-backups)
6. [Application Backups](#application-backups)
7. [Configuration Backups](#configuration-backups)
8. [Automated Backup Solutions](#automated-backup-solutions)
9. [Backup Storage](#backup-storage)
10. [Backup Verification](#backup-verification)
11. [Disaster Recovery](#disaster-recovery)
12. [Point-in-Time Recovery](#point-in-time-recovery)
13. [Backup Monitoring](#backup-monitoring)
14. [Best Practices](#best-practices)
15. [Troubleshooting](#troubleshooting)

## Overview

A comprehensive backup and recovery strategy is critical for protecting data and ensuring business continuity. This guide covers backup procedures, retention policies, testing, and recovery processes.

### Backup Architecture

```
┌─────────────────────────────────────────────────┐
│          Production Environment                  │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Database │  │   Files  │  │  Config  │     │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘     │
│        │             │              │           │
└────────┼─────────────┼──────────────┼──────────┘
         │             │              │
    ┌────▼─────────────▼──────────────▼────┐
    │      Backup Server (Local)            │
    │  ┌─────────────────────────────────┐  │
    │  │   Daily/Weekly/Monthly          │  │
    │  │   Backup Storage                │  │
    │  └─────────────┬───────────────────┘  │
    └────────────────┼──────────────────────┘
                     │
            ┌────────▼────────┐
            │  Offsite/Cloud  │
            │  Backup Storage │
            │  (S3/Glacier)   │
            └─────────────────┘
```

### 3-2-1 Backup Rule

Follow the 3-2-1 rule:
- **3** copies of data (1 primary + 2 backups)
- **2** different media types
- **1** copy offsite

## Prerequisites

### System Requirements
- **Storage**: At least 3x production data size for local backups
- **Bandwidth**: Sufficient for offsite backup transfers
- **Backup Server**: Dedicated server or service for storing backups
- **Monitoring**: System for backup verification and alerting

### Software Requirements
- **mysqldump** or **Percona XtraBackup** (database)
- **rsync** or **restic** (files)
- **tar** and **gzip** (compression)
- **AWS CLI** or similar (cloud storage)
- **GPG** (encryption)
- **Monitoring tools** (Nagios, Zabbix, or custom scripts)

### Access Requirements
- Root or sudo access
- Database credentials with backup privileges
- S3 or cloud storage credentials
- SSH access to backup server
- Encrypted credential storage

## Backup Strategy

### Backup Schedule

#### Production Environment

| Backup Type | Frequency | Retention | Storage Location |
|-------------|-----------|-----------|------------------|
| Full Database | Daily (2 AM) | 30 days | Local + Offsite |
| Incremental DB | Every 6 hours | 7 days | Local |
| Binary Logs | Continuous | 7 days | Local + Offsite |
| Application Files | Daily (3 AM) | 30 days | Local + Offsite |
| User Uploads | Daily (4 AM) | 90 days | Local + Offsite |
| Configuration | On Change + Daily | 90 days | Local + Offsite |
| System State | Weekly | 30 days | Local + Offsite |

#### Development/Staging Environment

| Backup Type | Frequency | Retention | Storage Location |
|-------------|-----------|-----------|------------------|
| Full Database | Weekly | 14 days | Local |
| Application Files | Weekly | 14 days | Local |

### Retention Policy

```
Daily Backups:    Keep for 30 days
Weekly Backups:   Keep for 90 days (12 weeks)
Monthly Backups:  Keep for 1 year (12 months)
Yearly Backups:   Keep for 7 years
```

## Database Backups

### Logical Backup with mysqldump

#### Full Database Backup Script

```bash
#!/bin/bash
# /usr/local/bin/mysql-backup.sh

set -e

# Configuration
BACKUP_DIR="/backup/mysql"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/mysql-backup.log"

# MySQL credentials (stored securely)
MYSQL_USER="backup_user"
MYSQL_PASSWORD=$(cat /root/.mysql_backup_password)
MYSQL_HOST="localhost"

# S3 Configuration
S3_BUCKET="s3://your-backup-bucket/mysql"
AWS_PROFILE="backup"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

log "Starting MySQL backup..."

# List of databases to backup
DATABASES=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

# Backup each database
for DB in $DATABASES; do
    log "Backing up database: $DB"

    BACKUP_FILE="$BACKUP_DIR/${DB}_${DATE}.sql.gz"

    # Create backup with compression
    mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --routines \
        --triggers \
        --events \
        "$DB" | gzip > "$BACKUP_FILE"

    # Check if backup was successful
    if [ $? -eq 0 ]; then
        log "Backup successful: $BACKUP_FILE"

        # Calculate checksum
        md5sum "$BACKUP_FILE" > "${BACKUP_FILE}.md5"

        # Encrypt backup
        gpg --encrypt --recipient backup@yourdomain.com "$BACKUP_FILE"

        # Upload to S3
        aws s3 cp "${BACKUP_FILE}.gpg" "$S3_BUCKET/" --profile "$AWS_PROFILE" --storage-class STANDARD_IA
        aws s3 cp "${BACKUP_FILE}.md5" "$S3_BUCKET/" --profile "$AWS_PROFILE"

        log "Uploaded to S3: ${BACKUP_FILE}.gpg"
    else
        log "ERROR: Backup failed for database: $DB"
        # Send alert
        echo "MySQL backup failed for $DB" | mail -s "Backup Alert" admin@yourdomain.com
    fi
done

# Backup all databases in one file (for easier restore)
log "Creating full backup of all databases..."
FULL_BACKUP="$BACKUP_DIR/all_databases_${DATE}.sql.gz"

mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" \
    --all-databases \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --routines \
    --triggers \
    --events \
    --master-data=2 | gzip > "$FULL_BACKUP"

if [ $? -eq 0 ]; then
    log "Full backup successful: $FULL_BACKUP"
    md5sum "$FULL_BACKUP" > "${FULL_BACKUP}.md5"
    gpg --encrypt --recipient backup@yourdomain.com "$FULL_BACKUP"
    aws s3 cp "${FULL_BACKUP}.gpg" "$S3_BUCKET/" --profile "$AWS_PROFILE" --storage-class STANDARD_IA
else
    log "ERROR: Full backup failed"
fi

# Cleanup old local backups
log "Cleaning up old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.sql.gz.gpg" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.md5" -mtime +$RETENTION_DAYS -delete

log "MySQL backup completed successfully"
```

#### Create MySQL Backup User

```sql
-- Create dedicated backup user with minimal privileges
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER, RELOAD ON *.* TO 'backup_user'@'localhost';
GRANT REPLICATION CLIENT ON *.* TO 'backup_user'@'localhost';
FLUSH PRIVILEGES;
```

#### Store Credentials Securely

```bash
# Store password in secure file
echo "STRONG_PASSWORD" | sudo tee /root/.mysql_backup_password
sudo chmod 400 /root/.mysql_backup_password
sudo chown root:root /root/.mysql_backup_password
```

### Physical Backup with Percona XtraBackup

#### Install XtraBackup

```bash
# Install Percona repository
sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
sudo percona-release enable-only tools release

# Install XtraBackup
sudo yum install -y percona-xtrabackup-80
```

#### Full Backup Script

```bash
#!/bin/bash
# /usr/local/bin/xtrabackup-full.sh

set -e

BACKUP_DIR="/backup/xtrabackup/full"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"
LOG_FILE="/var/log/xtrabackup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_PATH"

log "Starting XtraBackup full backup..."

# Perform backup
xtrabackup --backup \
    --target-dir="$BACKUP_PATH" \
    --user=backup_user \
    --password=$(cat /root/.mysql_backup_password) \
    2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "Backup successful: $BACKUP_PATH"

    # Compress backup
    tar -czf "${BACKUP_PATH}.tar.gz" -C "$BACKUP_DIR" "$DATE"

    # Encrypt and upload to S3
    gpg --encrypt --recipient backup@yourdomain.com "${BACKUP_PATH}.tar.gz"
    aws s3 cp "${BACKUP_PATH}.tar.gz.gpg" s3://your-backup-bucket/xtrabackup/

    # Cleanup uncompressed backup
    rm -rf "$BACKUP_PATH"

    log "XtraBackup completed successfully"
else
    log "ERROR: XtraBackup failed"
    exit 1
fi
```

#### Incremental Backup Script

```bash
#!/bin/bash
# /usr/local/bin/xtrabackup-incremental.sh

set -e

BACKUP_DIR="/backup/xtrabackup"
FULL_BACKUP_DIR="$BACKUP_DIR/full"
INCREMENTAL_DIR="$BACKUP_DIR/incremental"
DATE=$(date +%Y%m%d_%H%M%S)

# Find latest full backup
LATEST_FULL=$(ls -td $FULL_BACKUP_DIR/*/ | head -1)

# Find latest incremental (or use full as base)
LATEST_INCREMENTAL=$(ls -td $INCREMENTAL_DIR/*/ 2>/dev/null | head -1)
BASE_DIR=${LATEST_INCREMENTAL:-$LATEST_FULL}

mkdir -p "$INCREMENTAL_DIR/$DATE"

# Perform incremental backup
xtrabackup --backup \
    --target-dir="$INCREMENTAL_DIR/$DATE" \
    --incremental-basedir="$BASE_DIR" \
    --user=backup_user \
    --password=$(cat /root/.mysql_backup_password)

if [ $? -eq 0 ]; then
    echo "Incremental backup successful"
else
    echo "ERROR: Incremental backup failed"
    exit 1
fi
```

### Binary Log Backup

```bash
#!/bin/bash
# /usr/local/bin/mysql-binlog-backup.sh

BINLOG_DIR="/var/lib/mysql"
BACKUP_DIR="/backup/binlogs"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR/$DATE"

# Flush logs to start new binlog
mysql -u backup_user -p$(cat /root/.mysql_backup_password) -e "FLUSH BINARY LOGS;"

# Copy binlogs (except the current one)
CURRENT_BINLOG=$(mysql -u backup_user -p$(cat /root/.mysql_backup_password) -e "SHOW MASTER STATUS\G" | grep File | awk '{print $2}')

for binlog in $(ls $BINLOG_DIR/mysql-bin.* | grep -v $CURRENT_BINLOG | grep -v ".index"); do
    cp "$binlog" "$BACKUP_DIR/$DATE/"
done

# Compress and upload
tar -czf "$BACKUP_DIR/binlogs_${DATE}.tar.gz" -C "$BACKUP_DIR" "$DATE"
aws s3 cp "$BACKUP_DIR/binlogs_${DATE}.tar.gz" s3://your-backup-bucket/binlogs/

# Cleanup old binlogs (keep 7 days)
find "$BACKUP_DIR" -name "binlogs_*.tar.gz" -mtime +7 -delete
```

## File System Backups

### Application Files Backup with rsync

```bash
#!/bin/bash
# /usr/local/bin/backup-application-files.sh

set -e

# Configuration
SOURCE_DIRS=(
    "/var/www/production/whm"
    "/var/www/production/cpanel"
    "/var/www/production/admin"
)
BACKUP_ROOT="/backup/applications"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
LOG_FILE="/var/log/application-backup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create backup directory
BACKUP_DIR="$BACKUP_ROOT/$DATE"
mkdir -p "$BACKUP_DIR"

log "Starting application files backup..."

# Backup each application
for SOURCE in "${SOURCE_DIRS[@]}"; do
    APP_NAME=$(basename "$SOURCE")
    log "Backing up $APP_NAME..."

    # Exclude unnecessary directories
    rsync -avz \
        --exclude='storage/logs/*' \
        --exclude='storage/framework/cache/*' \
        --exclude='storage/framework/sessions/*' \
        --exclude='storage/framework/views/*' \
        --exclude='node_modules' \
        --exclude='vendor' \
        --exclude='.git' \
        "$SOURCE" "$BACKUP_DIR/" 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "Backup successful for $APP_NAME"
    else
        log "ERROR: Backup failed for $APP_NAME"
    fi
done

# Compress backup
log "Compressing backup..."
tar -czf "$BACKUP_ROOT/applications_${DATE}.tar.gz" -C "$BACKUP_ROOT" "$DATE"

# Encrypt and upload
log "Encrypting and uploading to S3..."
gpg --encrypt --recipient backup@yourdomain.com "$BACKUP_ROOT/applications_${DATE}.tar.gz"
aws s3 cp "$BACKUP_ROOT/applications_${DATE}.tar.gz.gpg" s3://your-backup-bucket/applications/

# Calculate checksum
md5sum "$BACKUP_ROOT/applications_${DATE}.tar.gz" > "$BACKUP_ROOT/applications_${DATE}.tar.gz.md5"
aws s3 cp "$BACKUP_ROOT/applications_${DATE}.tar.gz.md5" s3://your-backup-bucket/applications/

# Cleanup
rm -rf "$BACKUP_DIR"
find "$BACKUP_ROOT" -name "applications_*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_ROOT" -name "applications_*.tar.gz.gpg" -mtime +$RETENTION_DAYS -delete

log "Application files backup completed"
```

### User Uploads Backup

```bash
#!/bin/bash
# /usr/local/bin/backup-user-uploads.sh

set -e

SOURCE="/var/www/production/whm/storage/app/public/uploads"
BACKUP_DIR="/backup/uploads"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/uploads-backup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"

log "Starting user uploads backup..."

# Incremental backup using rsync
rsync -avz \
    --link-dest="$BACKUP_DIR/latest" \
    "$SOURCE/" \
    "$BACKUP_DIR/$DATE/" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    # Update latest symlink
    rm -f "$BACKUP_DIR/latest"
    ln -s "$BACKUP_DIR/$DATE" "$BACKUP_DIR/latest"

    log "Uploads backup successful"

    # Sync to S3
    aws s3 sync "$BACKUP_DIR/$DATE/" s3://your-backup-bucket/uploads/$DATE/ --storage-class GLACIER
else
    log "ERROR: Uploads backup failed"
    exit 1
fi

# Cleanup old backups (keep 90 days)
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \;

log "User uploads backup completed"
```

### Backup with Restic

```bash
# Install restic
sudo yum install -y restic

# Initialize repository
restic -r /backup/restic init

# Or use S3
restic -r s3:s3.amazonaws.com/your-backup-bucket init

# Create backup
restic -r /backup/restic backup /var/www/production \
    --exclude='*/storage/logs/*' \
    --exclude='*/storage/framework/cache/*' \
    --exclude='*/node_modules/*' \
    --exclude='*/vendor/*'

# List snapshots
restic -r /backup/restic snapshots

# Restore
restic -r /backup/restic restore latest --target /var/www/restored
```

## Configuration Backups

### System Configuration Backup

```bash
#!/bin/bash
# /usr/local/bin/backup-configuration.sh

set -e

BACKUP_DIR="/backup/configuration"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"

mkdir -p "$BACKUP_PATH"

# Backup important configuration directories
CONFIG_DIRS=(
    "/etc/httpd"
    "/etc/php.ini"
    "/etc/php-fpm.d"
    "/etc/my.cnf"
    "/etc/my.cnf.d"
    "/etc/redis.conf"
    "/etc/haproxy"
    "/etc/systemd/system"
    "/etc/cron.d"
    "/etc/sysconfig"
)

for CONFIG in "${CONFIG_DIRS[@]}"; do
    if [ -e "$CONFIG" ]; then
        DEST_PATH="$BACKUP_PATH$(dirname $CONFIG)"
        mkdir -p "$DEST_PATH"
        cp -R "$CONFIG" "$DEST_PATH/"
    fi
done

# Backup application .env files
find /var/www/production -name ".env" -exec sh -c 'mkdir -p "$1$(dirname $2)" && cp "$2" "$1$2"' _ "$BACKUP_PATH" {} \;

# Backup crontab
crontab -l > "$BACKUP_PATH/crontab.backup" 2>/dev/null || true

# Backup list of installed packages
rpm -qa > "$BACKUP_PATH/installed_packages.txt"

# Backup network configuration
ip addr show > "$BACKUP_PATH/network_config.txt"
ip route show > "$BACKUP_PATH/network_routes.txt"

# Compress and encrypt
tar -czf "$BACKUP_DIR/configuration_${DATE}.tar.gz" -C "$BACKUP_DIR" "$DATE"
gpg --encrypt --recipient backup@yourdomain.com "$BACKUP_DIR/configuration_${DATE}.tar.gz"

# Upload to S3
aws s3 cp "$BACKUP_DIR/configuration_${DATE}.tar.gz.gpg" s3://your-backup-bucket/configuration/

# Cleanup
rm -rf "$BACKUP_PATH"
find "$BACKUP_DIR" -name "configuration_*.tar.gz" -mtime +90 -delete
```

## Automated Backup Solutions

### Comprehensive Backup Script

```bash
#!/bin/bash
# /usr/local/bin/master-backup.sh

set -e

LOG_FILE="/var/log/master-backup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Send notification
notify() {
    local subject="$1"
    local message="$2"
    echo "$message" | mail -s "$subject" admin@yourdomain.com
}

log "========================================="
log "Starting master backup process"
log "========================================="

# Run backups in sequence
BACKUP_SCRIPTS=(
    "/usr/local/bin/mysql-backup.sh"
    "/usr/local/bin/backup-application-files.sh"
    "/usr/local/bin/backup-user-uploads.sh"
    "/usr/local/bin/backup-configuration.sh"
)

FAILED_BACKUPS=()

for SCRIPT in "${BACKUP_SCRIPTS[@]}"; do
    log "Executing: $SCRIPT"

    if [ -x "$SCRIPT" ]; then
        if $SCRIPT >> "$LOG_FILE" 2>&1; then
            log "SUCCESS: $SCRIPT"
        else
            log "FAILED: $SCRIPT"
            FAILED_BACKUPS+=("$SCRIPT")
        fi
    else
        log "ERROR: Script not found or not executable: $SCRIPT"
        FAILED_BACKUPS+=("$SCRIPT")
    fi
done

log "========================================="
log "Master backup process completed"
log "========================================="

# Send summary notification
if [ ${#FAILED_BACKUPS[@]} -eq 0 ]; then
    notify "Backup Success" "All backups completed successfully on $(hostname)"
else
    FAILED_LIST=$(printf '%s\n' "${FAILED_BACKUPS[@]}")
    notify "Backup Failure" "Some backups failed on $(hostname):\n$FAILED_LIST"
fi
```

### Schedule with Cron

```bash
# Edit crontab
sudo crontab -e
```

```cron
# Database backup - daily at 2 AM
0 2 * * * /usr/local/bin/mysql-backup.sh

# Application files backup - daily at 3 AM
0 3 * * * /usr/local/bin/backup-application-files.sh

# User uploads backup - daily at 4 AM
0 4 * * * /usr/local/bin/backup-user-uploads.sh

# Configuration backup - daily at 5 AM
0 5 * * * /usr/local/bin/backup-configuration.sh

# Binary log backup - every 6 hours
0 */6 * * * /usr/local/bin/mysql-binlog-backup.sh

# XtraBackup full backup - weekly on Sunday at 1 AM
0 1 * * 0 /usr/local/bin/xtrabackup-full.sh

# XtraBackup incremental - daily except Sunday at 1 AM
0 1 * * 1-6 /usr/local/bin/xtrabackup-incremental.sh

# Master backup (all backups) - daily at 2 AM
0 2 * * * /usr/local/bin/master-backup.sh
```

## Backup Storage

### Local Storage Configuration

```bash
# Create backup directory structure
sudo mkdir -p /backup/{mysql,xtrabackup,binlogs,applications,uploads,configuration}
sudo mkdir -p /backup/xtrabackup/{full,incremental}

# Set permissions
sudo chmod 700 /backup
sudo chown -R root:root /backup

# Configure separate partition/volume for backups (recommended)
# Add to /etc/fstab
/dev/sdb1  /backup  ext4  defaults  0  2
```

### S3 Storage Configuration

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure --profile backup
# Enter:
# AWS Access Key ID
# AWS Secret Access Key
# Default region
# Output format (json)

# Create S3 bucket with versioning
aws s3api create-bucket \
    --bucket your-backup-bucket \
    --region us-east-1 \
    --profile backup

aws s3api put-bucket-versioning \
    --bucket your-backup-bucket \
    --versioning-configuration Status=Enabled \
    --profile backup

# Configure lifecycle policy
cat > lifecycle-policy.json << 'EOF'
{
    "Rules": [
        {
            "Id": "MoveToGlacier",
            "Status": "Enabled",
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "GLACIER"
                }
            ],
            "Expiration": {
                "Days": 365
            }
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket your-backup-bucket \
    --lifecycle-configuration file://lifecycle-policy.json \
    --profile backup

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket your-backup-bucket \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' \
    --profile backup
```

### Backup Encryption

```bash
# Generate GPG key
gpg --full-generate-key
# Select: RSA and RSA
# Key size: 4096
# Key expires: 0 (does not expire)
# Real name: Backup System
# Email: backup@yourdomain.com

# List keys
gpg --list-keys

# Export public key (for team members)
gpg --armor --export backup@yourdomain.com > backup-public-key.asc

# Import on another system
gpg --import backup-public-key.asc

# Encrypt file
gpg --encrypt --recipient backup@yourdomain.com file.tar.gz

# Decrypt file
gpg --decrypt file.tar.gz.gpg > file.tar.gz
```

## Backup Verification

### Automated Verification Script

```bash
#!/bin/bash
# /usr/local/bin/verify-backups.sh

set -e

LOG_FILE="/var/log/backup-verification.log"
BACKUP_DIR="/backup"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting backup verification..."

# Verify MySQL backups
log "Verifying MySQL backups..."
LATEST_MYSQL_BACKUP=$(ls -t $BACKUP_DIR/mysql/*.sql.gz 2>/dev/null | head -1)

if [ -n "$LATEST_MYSQL_BACKUP" ]; then
    # Check if file is not empty
    if [ -s "$LATEST_MYSQL_BACKUP" ]; then
        # Verify compression integrity
        if gzip -t "$LATEST_MYSQL_BACKUP" 2>/dev/null; then
            log "MySQL backup integrity verified: $LATEST_MYSQL_BACKUP"

            # Verify checksum
            if [ -f "${LATEST_MYSQL_BACKUP}.md5" ]; then
                if md5sum -c "${LATEST_MYSQL_BACKUP}.md5"; then
                    log "MySQL backup checksum verified"
                else
                    log "ERROR: MySQL backup checksum mismatch"
                fi
            fi
        else
            log "ERROR: MySQL backup is corrupted: $LATEST_MYSQL_BACKUP"
        fi
    else
        log "ERROR: MySQL backup is empty: $LATEST_MYSQL_BACKUP"
    fi
else
    log "ERROR: No MySQL backup found"
fi

# Verify application backups
log "Verifying application backups..."
LATEST_APP_BACKUP=$(ls -t $BACKUP_DIR/applications/*.tar.gz 2>/dev/null | head -1)

if [ -n "$LATEST_APP_BACKUP" ]; then
    if tar -tzf "$LATEST_APP_BACKUP" > /dev/null 2>&1; then
        log "Application backup integrity verified: $LATEST_APP_BACKUP"
    else
        log "ERROR: Application backup is corrupted: $LATEST_APP_BACKUP"
    fi
else
    log "ERROR: No application backup found"
fi

# Check backup age (should not be older than 25 hours)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +1 | while read OLD_BACKUP; do
    log "WARNING: Backup is older than 24 hours: $OLD_BACKUP"
done

# Check disk space
DISK_USAGE=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
    log "WARNING: Backup disk usage is high: ${DISK_USAGE}%"
fi

# Verify S3 backups
log "Verifying S3 backups..."
TODAY=$(date +%Y%m%d)
S3_BACKUP_COUNT=$(aws s3 ls s3://your-backup-bucket/ --recursive | grep "$TODAY" | wc -l)

if [ "$S3_BACKUP_COUNT" -gt 0 ]; then
    log "Found $S3_BACKUP_COUNT S3 backups for today"
else
    log "WARNING: No S3 backups found for today"
fi

log "Backup verification completed"
```

### Test Restore Procedure

```bash
#!/bin/bash
# /usr/local/bin/test-restore.sh

set -e

TEST_DIR="/tmp/restore-test-$(date +%s)"
LOG_FILE="/var/log/restore-test.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$TEST_DIR"

log "Starting restore test..."

# Test MySQL restore
log "Testing MySQL restore..."
LATEST_MYSQL_BACKUP=$(ls -t /backup/mysql/*.sql.gz | head -1)

if [ -n "$LATEST_MYSQL_BACKUP" ]; then
    # Create test database
    TEST_DB="restore_test_$(date +%s)"
    mysql -u root -p$(cat /root/.mysql_password) -e "CREATE DATABASE $TEST_DB;"

    # Restore backup
    gunzip < "$LATEST_MYSQL_BACKUP" | mysql -u root -p$(cat /root/.mysql_password) "$TEST_DB"

    # Verify restore
    TABLE_COUNT=$(mysql -u root -p$(cat /root/.mysql_password) -e "SHOW TABLES;" "$TEST_DB" | wc -l)

    if [ "$TABLE_COUNT" -gt 0 ]; then
        log "MySQL restore test successful: $TABLE_COUNT tables restored"
    else
        log "ERROR: MySQL restore test failed: No tables found"
    fi

    # Cleanup
    mysql -u root -p$(cat /root/.mysql_password) -e "DROP DATABASE $TEST_DB;"
else
    log "ERROR: No MySQL backup found for testing"
fi

# Test application files restore
log "Testing application files restore..."
LATEST_APP_BACKUP=$(ls -t /backup/applications/*.tar.gz | head -1)

if [ -n "$LATEST_APP_BACKUP" ]; then
    tar -xzf "$LATEST_APP_BACKUP" -C "$TEST_DIR"

    # Verify critical files
    CRITICAL_FILES=(
        "whm/artisan"
        "whm/composer.json"
        "cpanel/artisan"
        "admin/artisan"
    )

    ALL_FOUND=true
    for FILE in "${CRITICAL_FILES[@]}"; do
        if [ ! -f "$TEST_DIR/$FILE" ]; then
            log "ERROR: Critical file missing: $FILE"
            ALL_FOUND=false
        fi
    done

    if [ "$ALL_FOUND" = true ]; then
        log "Application files restore test successful"
    else
        log "ERROR: Application files restore test failed"
    fi
else
    log "ERROR: No application backup found for testing"
fi

# Cleanup
rm -rf "$TEST_DIR"

log "Restore test completed"
```

## Disaster Recovery

### Full System Recovery Procedure

#### Step 1: Prepare New Server

```bash
# Install base operating system
# Configure network, hostname, etc.

# Update system
sudo yum update -y

# Install required software
sudo yum install -y httpd php php-fpm mariadb-server redis git

# Configure firewall
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

#### Step 2: Restore Configuration

```bash
# Download configuration backup from S3
aws s3 cp s3://your-backup-bucket/configuration/latest.tar.gz.gpg /tmp/

# Decrypt
gpg --decrypt /tmp/latest.tar.gz.gpg > /tmp/config.tar.gz

# Extract
mkdir -p /tmp/config
tar -xzf /tmp/config.tar.gz -C /tmp/config

# Restore configuration files
sudo cp -R /tmp/config/etc/* /etc/

# Restore crontab
crontab /tmp/config/crontab.backup
```

#### Step 3: Restore Database

```bash
# Start MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Download database backup
aws s3 cp s3://your-backup-bucket/mysql/latest.sql.gz.gpg /tmp/

# Decrypt
gpg --decrypt /tmp/latest.sql.gz.gpg > /tmp/database.sql.gz

# Restore database
gunzip < /tmp/database.sql.gz | mysql -u root -p

# Verify restoration
mysql -u root -p -e "SHOW DATABASES;"
```

#### Step 4: Restore Application Files

```bash
# Download application backup
aws s3 cp s3://your-backup-bucket/applications/latest.tar.gz.gpg /tmp/

# Decrypt and extract
gpg --decrypt /tmp/latest.tar.gz.gpg | tar -xzf - -C /var/www/production

# Set permissions
sudo chown -R apache:apache /var/www/production
sudo chmod -R 755 /var/www/production
sudo chmod -R 775 /var/www/production/*/storage
sudo chmod -R 775 /var/www/production/*/bootstrap/cache

# Install dependencies
cd /var/www/production/whm
sudo -u apache composer install --no-dev --optimize-autoloader
```

#### Step 5: Restore User Uploads

```bash
# Download uploads
aws s3 sync s3://your-backup-bucket/uploads/latest/ /var/www/production/whm/storage/app/public/uploads/

# Set permissions
sudo chown -R apache:apache /var/www/production/whm/storage/app/public/uploads
```

#### Step 6: Start Services

```bash
# Start all services
sudo systemctl start httpd
sudo systemctl start php-fpm
sudo systemctl start redis
sudo systemctl start mariadb

# Enable services
sudo systemctl enable httpd
sudo systemctl enable php-fpm
sudo systemctl enable redis
sudo systemctl enable mariadb

# Verify services
sudo systemctl status httpd
sudo systemctl status php-fpm
sudo systemctl status redis
sudo systemctl status mariadb
```

#### Step 7: Verify Recovery

```bash
# Test application
curl -I https://whm.yourdomain.com

# Check logs
tail -f /var/log/httpd/error_log
tail -f /var/www/production/whm/storage/logs/laravel.log

# Test database connection
mysql -u whm_user -p whm_panel -e "SELECT COUNT(*) FROM users;"

# Test Redis
redis-cli ping
```

### Recovery Time Objective (RTO) and Recovery Point Objective (RPO)

| Service | RTO Target | RPO Target | Strategy |
|---------|------------|------------|----------|
| Database | 4 hours | 15 minutes | Binary log replay + Full backup |
| Application | 2 hours | 24 hours | S3 restore + Deploy |
| User Uploads | 4 hours | 24 hours | S3 sync |
| Configuration | 1 hour | 24 hours | S3 restore |

## Point-in-Time Recovery

### MySQL Point-in-Time Recovery

```bash
#!/bin/bash
# /usr/local/bin/mysql-pitr.sh

# Parameters
TARGET_TIME="$1"  # Format: "2023-10-23 14:30:00"
BACKUP_FILE="$2"
BINLOG_DIR="/backup/binlogs"

if [ -z "$TARGET_TIME" ] || [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 'YYYY-MM-DD HH:MM:SS' /path/to/backup.sql.gz"
    exit 1
fi

# Step 1: Restore full backup
echo "Restoring full backup..."
gunzip < "$BACKUP_FILE" | mysql -u root -p

# Step 2: Get backup position
BACKUP_BINLOG=$(gunzip < "$BACKUP_FILE" | grep "CHANGE MASTER TO" | grep -oP "MASTER_LOG_FILE='\\K[^']+")
BACKUP_POS=$(gunzip < "$BACKUP_FILE" | grep "CHANGE MASTER TO" | grep -oP "MASTER_LOG_POS=\\K[0-9]+")

echo "Backup position: $BACKUP_BINLOG at position $BACKUP_POS"

# Step 3: Find binlogs to apply
BINLOGS_TO_APPLY=$(ls -1 $BINLOG_DIR/mysql-bin.* | awk -v start="$BACKUP_BINLOG" '$0 >= start')

# Step 4: Apply binlogs up to target time
for BINLOG in $BINLOGS_TO_APPLY; do
    echo "Applying binlog: $BINLOG"
    mysqlbinlog --stop-datetime="$TARGET_TIME" "$BINLOG" | mysql -u root -p
done

echo "Point-in-time recovery completed to $TARGET_TIME"
```

## Backup Monitoring

### Backup Monitoring Script

```bash
#!/bin/bash
# /usr/local/bin/monitor-backups.sh

set -e

NAGIOS_OK=0
NAGIOS_WARNING=1
NAGIOS_CRITICAL=2

check_backup_age() {
    local backup_pattern="$1"
    local max_age_hours="$2"
    local backup_type="$3"

    LATEST_BACKUP=$(find /backup -name "$backup_pattern" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2)

    if [ -z "$LATEST_BACKUP" ]; then
        echo "CRITICAL: No $backup_type backup found"
        return $NAGIOS_CRITICAL
    fi

    BACKUP_AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")) / 3600 ))

    if [ $BACKUP_AGE_HOURS -gt $max_age_hours ]; then
        echo "WARNING: $backup_type backup is $BACKUP_AGE_HOURS hours old (threshold: $max_age_hours hours)"
        return $NAGIOS_WARNING
    fi

    echo "OK: $backup_type backup is $BACKUP_AGE_HOURS hours old"
    return $NAGIOS_OK
}

# Check MySQL backup (should not be older than 25 hours)
check_backup_age "*.sql.gz" 25 "MySQL"
MYSQL_STATUS=$?

# Check application backup (should not be older than 25 hours)
check_backup_age "applications_*.tar.gz" 25 "Application"
APP_STATUS=$?

# Check configuration backup (should not be older than 25 hours)
check_backup_age "configuration_*.tar.gz" 25 "Configuration"
CONFIG_STATUS=$?

# Overall status
if [ $MYSQL_STATUS -eq $NAGIOS_CRITICAL ] || [ $APP_STATUS -eq $NAGIOS_CRITICAL ] || [ $CONFIG_STATUS -eq $NAGIOS_CRITICAL ]; then
    exit $NAGIOS_CRITICAL
elif [ $MYSQL_STATUS -eq $NAGIOS_WARNING ] || [ $APP_STATUS -eq $NAGIOS_WARNING ] || [ $CONFIG_STATUS -eq $NAGIOS_WARNING ]; then
    exit $NAGIOS_WARNING
else
    exit $NAGIOS_OK
fi
```

### Prometheus Metrics

```bash
# Create metrics exporter
cat > /usr/local/bin/backup-metrics.sh << 'EOF'
#!/bin/bash

METRICS_FILE="/var/lib/node_exporter/textfile_collector/backup_metrics.prom"
mkdir -p "$(dirname $METRICS_FILE)"

# Backup age metrics
for TYPE in mysql applications uploads configuration; do
    LATEST=$(find /backup -name "${TYPE}_*.tar.gz" -type f -printf '%T@\n' | sort -rn | head -1)
    if [ -n "$LATEST" ]; then
        AGE=$(( $(date +%s) - ${LATEST%.*} ))
        echo "backup_age_seconds{type=\"$TYPE\"} $AGE"
    fi
done > "$METRICS_FILE.$$"

# Backup size metrics
for TYPE in mysql applications uploads configuration; do
    SIZE=$(find /backup -name "${TYPE}_*.tar.gz" -type f -printf '%s\n' | head -1)
    if [ -n "$SIZE" ]; then
        echo "backup_size_bytes{type=\"$TYPE\"} $SIZE"
    fi
done >> "$METRICS_FILE.$$"

# Backup count metrics
for TYPE in mysql applications uploads configuration; do
    COUNT=$(find /backup -name "${TYPE}_*.tar.gz" -type f | wc -l)
    echo "backup_count{type=\"$TYPE\"} $COUNT"
done >> "$METRICS_FILE.$$"

mv "$METRICS_FILE.$$" "$METRICS_FILE"
EOF

chmod +x /usr/local/bin/backup-metrics.sh

# Add to cron
echo "*/5 * * * * /usr/local/bin/backup-metrics.sh" | crontab -
```

## Best Practices

### 1. Test Restores Regularly

```bash
# Schedule monthly restore tests
0 2 1 * * /usr/local/bin/test-restore.sh
```

### 2. Encrypt All Backups

Always encrypt sensitive data before storage:
- Use GPG for file encryption
- Use SSL/TLS for transfer encryption
- Use S3 server-side encryption

### 3. Implement Backup Monitoring

- Monitor backup completion
- Monitor backup age
- Monitor storage capacity
- Alert on failures

### 4. Document Recovery Procedures

Maintain updated documentation:
- Step-by-step recovery procedures
- Contact information
- Access credentials (encrypted)
- Network diagrams

### 5. Offsite Storage

Always maintain offsite copies:
- Different geographic location
- Different cloud provider (optional)
- Physical media in secure location

## Troubleshooting

### Common Issues

#### 1. Backup Too Large

```bash
# Split large backups
mysqldump --single-transaction whm_panel | split -b 1G - backup.sql.
gzip backup.sql.*

# Or backup tables individually
for TABLE in $(mysql -u root -p -e "SHOW TABLES FROM whm_panel" | grep -v Tables_in); do
    mysqldump whm_panel $TABLE | gzip > whm_panel_${TABLE}.sql.gz
done
```

#### 2. Backup Taking Too Long

```bash
# Use XtraBackup for physical backups (faster)
# Increase compression level for faster backups
gzip -1 instead of gzip -9

# Parallel backup with mydumper
mydumper --database whm_panel --threads 4 --compress --outputdir /backup/mydumper
```

#### 3. Out of Disk Space

```bash
# Check disk usage
df -h /backup

# Cleanup old backups immediately
find /backup -name "*.tar.gz" -mtime +7 -delete

# Compress backups better
recompress-backups.sh

# Move old backups to Glacier
aws s3 cp /backup/old/ s3://bucket/archive/ --storage-class GLACIER
```

#### 4. S3 Upload Failures

```bash
# Use multipart upload for large files
aws s3 cp large-file.tar.gz s3://bucket/ --storage-class STANDARD_IA

# Retry failed uploads
aws s3 sync /backup s3://bucket/backup/ --storage-class STANDARD_IA

# Use AWS DataSync for large transfers
```

#### 5. Corrupted Backup

```bash
# Verify backup integrity
gzip -t backup.sql.gz
tar -tzf backup.tar.gz > /dev/null

# Use parchive for error correction
par2create -r10 backup.tar.gz
# On restore:
par2verify backup.tar.gz.par2
par2repair backup.tar.gz.par2
```

---

**Related Documentation:**
- [Production Deployment Guide](production.md)
- [Docker Deployment Guide](docker.md)
- [Scaling Guide](scaling.md)
