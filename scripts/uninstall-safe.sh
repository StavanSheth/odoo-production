#!/usr/bin/env bash
# =============================================================================
# Safe Stack Teardown & Uninstall Script
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "============================================================"
echo " Odoo 18 Teardown & Uninstall Menu"
echo "============================================================"
echo "1) Stop containers (Preserve all databases and filestores)"
echo "2) Full uninstall (Remove containers, networks, and DATA VOLUMES)"
echo "3) Cancel"
read -p "Select option (1-3): " CHOICE

case "$CHOICE" in
  1)
    echo "[*] Stopping containers..."
    docker compose stop
    echo "[+] Containers stopped. Data remains safe in Docker volumes."
    ;;
  2)
    echo "[!] CAUTION: This will delete all databases, filestores, and attachments!"
    read -p "Type 'DELETE' to confirm irreversible wipe: " CONFIRM
    if [ "$CONFIRM" == "DELETE" ]; then
      echo "[*] Tearing down stack and purging volumes..."
      docker compose down -v
      echo "[+] All containers, networks, and persistent data volumes removed."
    else
      echo "[*] Aborted by user."
    fi
    ;;
  *)
    echo "[*] Exiting without changes."
    ;;
esac

