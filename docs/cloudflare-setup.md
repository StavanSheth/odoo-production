# Cloudflare Setup & Tunnel Configuration

## Overview
Using **Cloudflare Tunnel (`cloudflared`)** eliminates the need to expose inbound ports (like 80, 443, 8069, or 5432) on your cloud server. The tunnel establishes an outbound encrypted QUIC/HTTP2 connection to Cloudflare's nearest edge data center.

---

## Production Setup (Named Tunnel with Custom Domain)

1. **Create Tunnel**:
   * Navigate to **Cloudflare Zero Trust** > **Networks** > **Tunnels**.
   * Click **Create a Tunnel** > Select **Cloudflared**.
   * Name your tunnel (e.g. `odoo-production`).
2. **Copy Tunnel Token**:
   * Copy the token value provided in the Docker command.
   * Add to `.env`:
     ```bash
     CLOUDFLARE_TUNNEL_TOKEN=eyJh...
     CLOUDFLARE_HOSTNAME=erp.yourdomain.com
     ```
3. **Configure Public Hostname**:
   * Subdomain: `erp`
   * Domain: `yourdomain.com`
   * Service Type: `HTTP`
   * URL: `nginx:80` (or `http://nginx:80`)
   * Under **Additional Application Settings** > **HTTP Settings**:
     * Enable **HTTP2** / **WebSockets**.
4. **Launch Tunnel**:
   ```bash
   docker compose --profile tunnel up -d cloudflared
   ```

---

## Temporary Quick Tunnel (No Domain / No Account)
For rapid temporary testing without a custom domain:
```bash
docker run --rm --network odoo_internal_network cloudflare/cloudflared:latest tunnel --url http://nginx:80
```
This generates a temporary `*.trycloudflare.com` URL. Note: Quick tunnels do not have an SLA and are not intended for 24/7 production use.

