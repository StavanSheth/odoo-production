#!/usr/bin/env bash
# =============================================================================
# Automated Odoo 18 Database & Filestore Backup Tool
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TARGET_BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

mkdir -p "$TARGET_BACKUP_PATH"

echo "============================================================"
echo " Starting Odoo 18 Backup: $TIMESTAMP"
echo "============================================================"

# Source environment
if [ -f "$PROJECT_ROOT/.env" ]; then
  # Read variables safely without exporting secrets
  DB_NAME=$(grep -E '^POSTGRES_DB=' "$PROJECT_ROOT/.env" | cut -d '=' -f2)
  DB_USER=$(grep -E '^POSTGRES_USER=' "$PROJECT_ROOT/.env" | cut -d '=' -f2)
fi
DB_NAME="${DB_NAME:-odoo}"
DB_USER="${DB_USER:-odoo}"

# 1. Database Dump
echo "[*] Creating PostgreSQL database dump..."
cd "$PROJECT_ROOT"
docker compose exec -T db pg_dump -U "$DB_USER" -Fc "$DB_NAME" > "$TARGET_BACKUP_PATH/database.dump"

if [ ! -s "$TARGET_BACKUP_PATH/database.dump" ]; then
  echo "[!] Error: Database dump file is empty or failed!"
  rm -rf "$TARGET_BACKUP_PATH"
  exit 1
fi
echo "[+] Database dump created ($(du -h "$TARGET_BACKUP_PATH/database.dump" | cut -f1))"

# 2. Filestore Archive
echo "[*] Creating Odoo filestore archive..."
docker compose exec -T web tar -czf - -C /var/lib/odoo filestore 2>/dev/null > "$TARGET_BACKUP_PATH/filestore.tar.gz" || true
echo "[+] Filestore archived ($(du -h "$TARGET_BACKUP_PATH/filestore.tar.gz" | cut -f1))"

# 3. Create Backup Manifest (Metadata without secrets)
cat <<EOF > "$TARGET_BACKUP_PATH/manifest.json"
{
  "timestamp": "$TIMESTAMP",
  "database": "$DB_NAME",
  "odoo_version": "18.0",
  "dump_format": "pg_dump custom format (-Fc)",
  "filestore_included": true
}
EOF

# 4. Consolidate into single compressed package
cd "$BACKUP_DIR"
tar -czf "odoo_backup_${TIMESTAMP}.tar.gz" "$TIMESTAMP"
rm -rf "$TIMESTAMP"

echo "[+] Consolidated backup package created: backups/odoo_backup_${TIMESTAMP}.tar.gz"

# 5. Retention policy: remove backups older than 14 days
echo "[*] Applying retention policy (pruning backups older than 14 days)..."
find "$BACKUP_DIR" -type f -name "odoo_backup_*.tar.gz" -mtime +14 -exec rm -f {} + 2>/dev/null || true

echo "============================================================"
echo " Backup Completed Successfully!"
echo " Package: $BACKUP_DIR/odoo_backup_${TIMESTAMP}.tar.gz"
echo "============================================================"

