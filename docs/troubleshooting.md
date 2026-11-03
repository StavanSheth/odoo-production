# Troubleshooting Guide

## Common Issues & Resolutions

### 1. 502 Bad Gateway from Nginx
* **Cause**: Odoo is still booting or crashed during startup.
* **Diagnosis**: `docker compose logs --tail 50 web`
* **Fix**: Ensure PostgreSQL is healthy (`docker inspect --format='{{json .State.Health.Status}}' odoo_db`). Check that database credentials in `.env` match `config/odoo.conf`.

### 2. WebSocket Returns 400 Bad Request
* **Cause**: Missing or mismatched `Origin` header.
* **Explanation**: Odoo 18 protects against Cross-Site WebSocket Hijacking by validating that the WebSocket `Origin` matches the request host. Ensure your reverse proxy passes `Host` and `X-Forwarded-Host`.

### 3. Database Manager Access Denied (403 Forbidden)
* **Cause**: By default, `nginx/default.conf` restricts access to `/web/database/manager` for security.
* **Access locally**: Use `http://localhost:8080/web/database/manager`.
* **Temporary unlock**: If remote access is needed, edit `nginx/default.conf` to add your public IP under `allow YOUR_IP;` and run `docker compose restart nginx`.

### 4. Out of Memory (OOM) on High Concurrency
* **Cause**: Too many workers or memory limits set too low.
* **Fix**: On 2 OCPUs / 12 GB RAM, set `workers = 5` and `limit_memory_soft = 2147483648` in `config/odoo.conf`.

