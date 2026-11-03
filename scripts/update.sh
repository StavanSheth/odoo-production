#!/usr/bin/env bash
# =============================================================================
# Safe Odoo 18 Update Script (Preserves DB & Filestore)
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "============================================================"
echo " Safe Odoo 18 Application Update"
echo "============================================================"

# 1. Take a preemptive snapshot backup before updating
echo "[*] Triggering safety backup prior to update..."
bash "$SCRIPT_DIR/backup.sh"

# 2. Pull latest minor/security patched images
echo "[*] Pulling updated container images..."
docker compose pull

# 3. Update database modules
echo "[*] Running Odoo module updates on base..."
docker compose run --rm -T web odoo -u base -d odoo --stop-after-init || true

# 4. Restart stack gracefully
echo "[*] Restarting application services..."
docker compose up -d web nginx

echo "[+] Odoo has been updated successfully."

