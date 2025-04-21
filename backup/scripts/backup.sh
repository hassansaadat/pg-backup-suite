#!/bin/bash

set -e

# Arguments from env/crontab
DB_NAME=$1
DB_USER=$2
DB_PASSWORD=$3
DB_HOST=$4
DB_PORT=$5

TIMESTAMP=$(date -Iseconds)

# File paths
FILENAME="db-backup-$DB_NAME-$TIMESTAMP.sql.gz.gpg"
TMP_SQL="/tmp/db-backup-$DB_NAME-$TIMESTAMP.sql"
TMP_GZ="$TMP_SQL.gz"
TMP_GPG="$TMP_GZ.gpg"

# Directories
LOCAL_BACKUP_DIR="/app/local_backups/$DB_NAME"
mkdir -p "$LOCAL_BACKUP_DIR"

# Set PGPASSWORD
export PGPASSWORD="$DB_PASSWORD"

log() {
  echo "[$(date -Iseconds)] $1"
}

log "🔄 Starting backup for $DB_NAME"

# Backup
if pg_dump -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$DB_NAME" --no-owner --no-acl > "$TMP_SQL"; then
  log "📄 Dump created successfully"
else
  log "❌ Failed to dump database"
  exit 1
fi

# Compress
gzip "$TMP_SQL"
log "📦 Compressed backup"

# Encrypt
gpg --batch --yes --passphrase "$BACKUP_ENCRYPTION_PASSPHRASE" \
    --output "$TMP_GPG" --symmetric "$TMP_GZ"
log "🔐 Encrypted backup"

# S3 Upload
# Ensure setting bucket level object lock in compliance/governance mode when creating bucket
mc alias set s3 "$AWS_ENDPOINT" "$AWS_ACCESS_KEY" "$AWS_SECRET_KEY" --api S3v4
if mc cp "$TMP_GPG" "s3/$AWS_BUCKET/$DB_NAME/$FILENAME"; then
  log "☁️ Uploaded to S3: $DB_NAME/$FILENAME"
else
  log "❌ Failed to upload to S3"
fi

# Save locally
cp "$TMP_GPG" "$LOCAL_BACKUP_DIR/$FILENAME"
log "📁 Local copy saved: $LOCAL_BACKUP_DIR/$FILENAME"

# Cleanup old local files (>7 days)
find "$LOCAL_BACKUP_DIR" -type f -name "*.gpg" -mtime +7 -exec rm {} \;
log "🧹 Old backups cleaned in $LOCAL_BACKUP_DIR"

# Clean temp files
rm -f "$TMP_GZ" "$TMP_GPG"

log "✅ Backup finished for $DB_NAME"

echo -e "\n-----------------------------------------------\n"
