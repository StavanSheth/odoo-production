#!/usr/bin/env bash
# =============================================================================
# Automated Local Odoo 18 Setup for Linux / WSL2
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "============================================================"
echo "   Odoo 18 Community — Local Linux / WSL Init               "
echo "============================================================"

# 1. Check Docker & Docker Compose
if ! command -v docker &> /dev/null; then
  echo "[!] Docker CLI not found. Please install Docker first."
  exit 1
fi

if ! docker compose version &> /dev/null; then
  echo "[!] Docker Compose v2 not found."
  exit 1
fi

# 2. Check .env
if [ ! -f .env ]; then
  echo "[*] Creating fresh .env from template with random passwords..."
  DB_PASS=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
  MASTER_PASS=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)

  sed -e "s/replace_with_secure_random_db_password_32chars/$DB_PASS/" \
      -e "s/replace_with_secure_random_master_password_32chars/$MASTER_PASS/" \
      .env.example > .env
  echo "[+] Generated new .env successfully."
else
  echo "[+] Existing .env detected (preserving secrets)."
fi

# 3. Pull Images
echo "[*] Pulling Docker images..."
docker compose pull

# 4. Start Database & Wait for Health
echo "[*] Starting PostgreSQL database..."
docker compose up -d db

echo "[*] Waiting for PostgreSQL healthcheck..."
until [ "$(docker inspect --format='{{json .State.Health.Status}}' odoo_db 2>/dev/null)" == '"healthy"' ]; do
  sleep 1
done
echo "[+] PostgreSQL is healthy!"

# 5. Start Odoo & Nginx
echo "[*] Starting Odoo application server and Nginx proxy..."
docker compose up -d web nginx

echo ""
echo "============================================================"
echo "   Local Odoo 18 Stack Initialized Successfully!            "
echo "============================================================"
echo "👉 Local URL: http://localhost:8080"
echo ""
echo "Commands:"
echo "  View logs:        docker compose logs -f"
echo "  Stop containers:  docker compose stop"
echo "  Health check:     bash scripts/health-check.sh"
echo "============================================================"

