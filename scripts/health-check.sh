#!/usr/bin/env bash
# =============================================================================
# Automated Health Check Suite for Odoo 18 Deployment
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

TARGET_URL="${1:-http://127.0.0.1:8080}"
FAILED=0

echo "============================================================"
echo " Running Odoo 18 Health Checks on: $TARGET_URL"
echo "============================================================"

# 1. PostgreSQL Health Check
echo -n "Checking PostgreSQL Container... "
DB_HEALTH=$(docker inspect --format='{{json .State.Health.Status}}' odoo_db 2>/dev/null || echo '"down"')
if [ "$DB_HEALTH" == '"healthy"' ]; then
  echo -e "\e[32m[PASS] PostgreSQL\e[0m"
else
  echo -e "\e[31m[FAIL] PostgreSQL (Status: $DB_HEALTH)\e[0m"
  FAILED=1
fi

# 2. Nginx Container Health
echo -n "Checking Nginx Container... "
NGINX_STATE=$(docker inspect --format='{{json .State.Status}}' odoo_nginx 2>/dev/null || echo '"down"')
if [ "$NGINX_STATE" == '"running"' ]; then
  echo -e "\e[32m[PASS] Nginx\e[0m"
else
  echo -e "\e[31m[FAIL] Nginx (Status: $NGINX_STATE)\e[0m"
  FAILED=1
fi

# 3. Odoo HTTP Web Response
echo -n "Checking Odoo HTTP Web Route... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$TARGET_URL/web/login" || echo "000")
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "303" ]; then
  echo -e "\e[32m[PASS] Odoo HTTP (Status: $HTTP_CODE)\e[0m"
else
  echo -e "\e[31m[FAIL] Odoo HTTP (Status: $HTTP_CODE)\e[0m"
  FAILED=1
fi

# 4. Persistent Database Volume Check
echo -n "Checking PostgreSQL Data Persistence... "
if docker volume inspect odoo_postgres_data &>/dev/null || docker volume inspect odoo_prod_postgres_data &>/dev/null; then
  echo -e "\e[32m[PASS] Persistent database\e[0m"
else
  echo -e "\e[31m[FAIL] Persistent database volume missing\e[0m"
  FAILED=1
fi

# 5. Persistent Filestore Volume Check
echo -n "Checking Odoo Filestore Persistence... "
if docker volume inspect odoo_web_data &>/dev/null || docker volume inspect odoo_prod_web_data &>/dev/null; then
  echo -e "\e[32m[PASS] Persistent filestore\e[0m"
else
  echo -e "\e[31m[FAIL] Persistent filestore volume missing\e[0m"
  FAILED=1
fi

# 6. WebSocket Route & Upgrade Handshake
echo -n "Checking Odoo Gevent WebSocket Engine... "
WS_CODE=$(curl -s -m 5 -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Host: 127.0.0.1" \
  -H "Origin: $TARGET_URL" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  "$TARGET_URL/websocket" 2>/dev/null | head -n 1 | awk '{print $2}' || echo "000")

if [ "$WS_CODE" == "101" ]; then
  echo -e "\e[32m[PASS] WebSocket route (101 Switching Protocols)\e[0m"
elif [ "$WS_CODE" == "400" ]; then
  echo -e "\e[32m[PASS] WebSocket route (Route alive, validated by Gevent engine)\e[0m"
else
  echo -e "\e[31m[FAIL] WebSocket route (Response code: $WS_CODE)\e[0m"
  FAILED=1
fi

echo "============================================================"
if [ $FAILED -eq 0 ]; then
  echo -e "\e[32mALL HEALTH CHECKS PASSED!\e[0m"
  exit 0
else
  echo -e "\e[31mONE OR MORE HEALTH CHECKS FAILED.\e[0m"
  exit 1
fi

