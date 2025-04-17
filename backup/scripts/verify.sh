#!/bin/bash

set -e

TIMESTAMP=$(date -Iseconds)
TMP_DIR="/tmp/verify"

mkdir -p "$TMP_DIR"

log() {
  echo "[$(date -Iseconds)] $1"
}

# Create & restore test DB
test_db_user=$(printenv "TEST_DB_USER")
test_db_password=$(printenv "TEST_DB_PASSWORD")
test_db_host=$(printenv "TEST_DB_HOST")
test_db_port=$(printenv "TEST_DB_PORT")

export PGPASSWORD=$test_db_password


i=1
while true; do
    var_name="DB${i}_NAME"
    db_name="${!var_name}"

    if [ -z "$db_name" ]; then
        break
    fi

  LOG_FILE="/app/logs/verify.log"
  BACKUP_DIR="/app/local_backups/$db_name"

  log "📦 Verifying backup for: $db_name"

  LATEST_BACKUP=$(ls -1 "$BACKUP_DIR"/*.gpg 2>/dev/null | sort | tail -n 1)

  if [ -z "$LATEST_BACKUP" ]; then
    log "❌ No backup file found in $BACKUP_DIR"
    i=$((i + 1))
    continue
  fi

  TMP_GZ="$TMP_DIR/${db_name}-latest.sql.gz"
  TMP_SQL="$TMP_DIR/${db_name}-latest.sql"

  # Decrypt
  gpg --batch --yes --passphrase "$BACKUP_ENCRYPTION_PASSPHRASE" \
      --output "$TMP_GZ" --decrypt "$LATEST_BACKUP"

  # Uncompress
  gunzip -c "$TMP_GZ" > "$TMP_SQL"

  psql -h $test_db_host -U $test_db_user -p $test_db_port -d postgres -c "DROP DATABASE IF EXISTS ${db_name}_restore_test;"
  psql -h $test_db_host -U $test_db_user -p $test_db_port -d postgres -c "CREATE DATABASE ${db_name}_restore_test;"

  if psql -h $test_db_host -U $test_db_user -p $test_db_port -d "${db_name}_restore_test" -f "$TMP_SQL"; then
    log "✅ Backup for $db_name successfully restored into test DB"
  else
    log "❌ Restore failed for $db_name"
  fi

  log "🧹 Cleaning up temporary files"

  rm -f "$TMP_GZ" "$TMP_SQL" || log "⚠️ Cleanup failed"

  i=$((i + 1))

  log "🏁 Local verification completed for $db_name"
  echo -e "\n-----------------------------------------------\n"

done
