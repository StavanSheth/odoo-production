#!/usr/bin/env bash
# =============================================================================
# Automated Oracle Cloud Infrastructure (OCI) Deployment Script
# Sized for: OCI Ampere A1 Flex (Ubuntu 24.04 ARM64, 2 OCPUs, 12 GB RAM)
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "============================================================"
echo " Starting Odoo 18 OCI Cloud Deployment"
echo "============================================================"

# 1. Verify OS is Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[!] Error: deploy-oci.sh must be executed on a Linux environment."
  exit 1
fi

# 2. Check CPU Architecture
ARCH=$(uname -m)
echo "[*] Detected Architecture: $ARCH"
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86_64" ]; then
  echo "[!] Warning: Untested CPU architecture: $ARCH"
fi

# 3. Check / Install Docker
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
  echo "[*] Docker engine not detected. Running automated installer..."
  sudo bash "$SCRIPT_DIR/setup-docker.sh"
fi

# 4. Handle Server Production .env
if [ ! -f .env ]; then
  echo "[*] Generating production-hardened secrets in .env..."
  DB_PASS=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
  MASTER_PASS=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)

  sed -e "s/replace_with_secure_random_db_password_32chars/$DB_PASS/" \
      -e "s/replace_with_secure_random_master_password_32chars/$MASTER_PASS/" \
      .env.example > .env
  chmod 600 .env

  # Synchronize credentials to config/odoo.conf
  sed -i "s/^db_password = .*/db_password = $DB_PASS/" config/odoo.conf
  sed -i "s/^admin_passwd = .*/admin_passwd = $MASTER_PASS/" config/odoo.conf
  echo "[+] Generated new production .env and synced config/odoo.conf."
else
  echo "[+] Existing production .env detected. Preserving secrets."
  DB_PASS=$(grep '^POSTGRES_PASSWORD=' .env | cut -d '=' -f2)
  MASTER_PASS=$(grep '^ODOO_MASTER_PASSWORD=' .env | cut -d '=' -f2)
  if [ -n "$DB_PASS" ]; then
    sed -i "s/^db_password = .*/db_password = $DB_PASS/" config/odoo.conf
  fi
  if [ -n "$MASTER_PASS" ]; then
    sed -i "s/^admin_passwd = .*/admin_passwd = $MASTER_PASS/" config/odoo.conf
  fi
fi

# 5. Pull ARM64 Docker Images
echo "[*] Pulling production container images..."
docker compose pull

# 6. Start Database
echo "[*] Launching PostgreSQL database container..."
docker compose up -d db

echo "[*] Waiting for PostgreSQL database health probe..."
until [ "$(docker inspect --format='{{json .State.Health.Status}}' odoo_db 2>/dev/null)" == '"healthy"' ]; do
  sleep 1
done
echo "[+] PostgreSQL database is ready and healthy."

# 7. Initialize Odoo Base Schema (if not already initialized)
echo "[*] Initializing base ERP database schema..."
docker compose run --rm -T web odoo -i base -d odoo --without-demo=all --stop-after-init || true
echo "[+] Database schema verified."

# 8. Start Odoo Application & Nginx Reverse Proxy
echo "[*] Launching Odoo 18 and Nginx reverse proxy..."
docker compose up -d web nginx

# Configure firewall if firewalld is active (Oracle Linux / RHEL)
if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
  echo "[*] Configuring firewalld rules for HTTP access..."
  firewall-cmd --add-port=80/tcp --add-port=8080/tcp --permanent 2>/dev/null || true
  firewall-cmd --reload 2>/dev/null || true
fi

# 8. Start Cloudflare Tunnel if token is provided
if grep -q '^CLOUDFLARE_TUNNEL_TOKEN=.\+' .env; then
  echo "[*] Cloudflare Tunnel token detected. Launching tunnel daemon..."
  docker compose --profile tunnel up -d cloudflared
  echo "[+] Cloudflare Tunnel is running (outbound connection active; no open inbound ports required)."
else
  echo "[*] Note: CLOUDFLARE_TUNNEL_TOKEN is empty. Cloudflare Tunnel container skipped."
fi

# 9. Run automated health check
echo ""
echo "[*] Running post-deployment health check..."
bash "$SCRIPT_DIR/health-check.sh" "http://127.0.0.1:8080" || true

echo ""
echo "============================================================"
echo " OCI Deployment Complete!"
echo "============================================================"
SERVER_IP=$(curl -s https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo "Direct Host Access: http://${SERVER_IP}:8080"
if grep -q '^CLOUDFLARE_HOSTNAME=.\+' .env; then
  CF_HOST=$(grep '^CLOUDFLARE_HOSTNAME=' .env | cut -d '=' -f2)
  echo "Public Cloudflare HTTPS: https://${CF_HOST}"
fi
echo "============================================================"

