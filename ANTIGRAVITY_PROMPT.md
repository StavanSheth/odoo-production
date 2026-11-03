# Master Specification: Odoo 18 Community Free-Tier Deployment

This repository implements the Master Implementation Specification for deploying Odoo 18 Community Edition across local Windows 11 / WSL2 environments and Oracle Cloud Infrastructure (OCI) Always Free tier.

## Key Directives Implemented
1. **Official Odoo Source**: Official `odoo:18.0` image with native ARM64 & AMD64 support. No core source modifications.
2. **PostgreSQL 15**: Isolated internal Docker bridge network without public port mapping.
3. **Nginx Reverse Proxy**:
   * Request buffering & 100MB client max body size.
   * Static asset caching (`/web/static/*`).
   * `/websocket` and `/websocket/` reverse proxy to port 8072 with HTTP/1.1 upgrade.
   * `/web/database/manager` lockdown against untrusted external IPs.
4. **Cloudflare Tunnel (`cloudflared`)**: Outbound tunnel connection; zero public inbound open ports needed.
5. **Automation Suite**:
   * Windows local initialization: `.\scripts\init-local.ps1`
   * Linux / WSL initialization: `bash scripts/init-local.sh`
   * Health checks: `bash scripts/health-check.sh`
   * Oracle Cloud deployment: `bash scripts/deploy-oci.sh`
   * Dual database + filestore backups: `bash scripts/backup.sh`
   * Safe restoration: `bash scripts/restore.sh`

