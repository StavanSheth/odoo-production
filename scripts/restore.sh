#!/usr/bin/env bash
# =============================================================================
# Automated Odoo 18 Database & Filestore Restore Tool
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "Usage: bash scripts/restore.sh <path_to_odoo_backup_tar_gz>"
  exit 1
fi

echo "============================================================"
echo " Odoo 18 Disaster Recovery / Restore Tool"
echo " Target Package: $BACKUP_FILE"
echo "============================================================"
echo "[!] WARNING: Restoring will overwrite existing database data and filestore!"
read -p "Type 'RESTORE' to proceed with overwrite: " CONFIRM

if [ "$CONFIRM" != "RESTORE" ]; then
  echo "[*] Restore aborted by user."
  exit 0
fi

# Source environment
if [ -f "$PROJECT_ROOT/.env" ]; then
  DB_NAME=$(grep -E '^POSTGRES_DB=' "$PROJECT_ROOT/.env" | cut -d '=' -f2)
  DB_USER=$(grep -E '^POSTGRES_USER=' "$PROJECT_ROOT/.env" | cut -d '=' -f2)
fi
DB_NAME="${DB_NAME:-odoo}"
DB_USER="${DB_USER:-odoo}"

TMP_RESTORE="/tmp/odoo_restore_$$"
mkdir -p "$TMP_RESTORE"

# 1. Unpack and verify integrity
echo "[*] Extracting and verifying backup package..."
tar -xzf "$BACKUP_FILE" -C "$TMP_RESTORE"

BACKUP_SUBDIR=$(find "$TMP_RESTORE" -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [ ! -f "$BACKUP_SUBDIR/database.dump" ]; then
  echo "[!] Corrupted backup archive: missing database.dump!"
  rm -rf "$TMP_RESTORE"
  exit 1
fi

# 2. Stop application server to prevent lockups during DB restore
echo "[*] Stopping Odoo application server..."
docker compose stop web

# 3. Restore PostgreSQL Database
echo "[*] Restoring database ($DB_NAME)..."
docker compose exec -T db dropdb -U "$DB_USER" --if-exists "$DB_NAME" || true
docker compose exec -T db createdb -U "$DB_USER" "$DB_NAME"
docker compose exec -T db pg_restore -U "$DB_USER" -d "$DB_NAME" --no-owner --clean < "$BACKUP_SUBDIR/database.dump" || true

# 4. Restore Filestore if present
if [ -f "$BACKUP_SUBDIR/filestore.tar.gz" ]; then
  echo "[*] Restoring filestore attachments..."
  docker compose run --rm -T web rm -rf /var/lib/odoo/filestore
  docker compose run --rm -T -v "$BACKUP_SUBDIR":/tmp/restore web tar -xzf /tmp/restore/filestore.tar.gz -C /var/lib/odoo
fi

# 5. Clean up and restart
rm -rf "$TMP_RESTORE"
echo "[*] Starting Odoo application server..."
docker compose start web

echo "============================================================"
echo " Restore Completed Successfully!"
echo " Stack has been restarted with the restored snapshot."
echo "============================================================"

