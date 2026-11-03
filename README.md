# Odoo 18 Community Free-Tier Deployment

A production-grade, zero-cost deployment template for **Odoo 18.0 Community Edition**, **PostgreSQL 15**, and **Nginx Reverse Proxy** with full WebSocket routing and **Cloudflare Tunnel** support.

Optimized for:
* **Local Development**: Windows 11 with Docker Desktop & WSL2 (`http://localhost:8080`)
* **Cloud Hosting**: Oracle Cloud Infrastructure (OCI) Always Free Ampere A1 (2 OCPUs, 12 GB RAM)

---

## Project Structure

```text
├── docker-compose.yml        # Base stack (DB, Odoo, Nginx, Cloudflared)
├── docker-compose.prod.yml   # Production override
├── .env                      # Local secrets (gitignored)
├── .env.example              # Secrets template
│
├── config/
│   └── odoo.conf             # Odoo 18 production configuration
├── nginx/
│   ├── nginx.conf            # Main Nginx configuration
│   └── default.conf          # Reverse proxy, caching, and WebSocket rules
│
├── scripts/
│   ├── init-local.ps1        # Automated PowerShell setup for Windows
│   ├── init-local.sh         # Automated bash setup for Linux/WSL
│   ├── deploy-oci.sh         # Automated Oracle Cloud deployment script
│   ├── setup-docker.sh       # Docker engine installer
│   ├── health-check.sh       # Automated health check test suite
│   ├── backup.sh             # Combined database + filestore backup
│   ├── restore.sh            # Safe restore with confirmation
│   ├── update.sh             # Safe image and module updater
│   └── uninstall-safe.sh     # Stack teardown with volume protection
│
├── backups/                  # Backup destination
├── extra-addons/             # Custom & third-party community modules
└── docs/                     # Comprehensive architecture and setup guides
```

---

## Quick Start (Local Windows Setup)

From PowerShell in this directory:
```powershell
.\scripts\init-local.ps1
```
Open **[http://localhost:8080](http://localhost:8080)** in your browser.

---

## Quick Start (Oracle Cloud Always Free Deployment)

On your Ubuntu 24.04 ARM64 server:
```bash
git clone <YOUR_GIT_REPO_URL> odoo18
cd odoo18
sudo bash scripts/deploy-oci.sh
```

---

## Documentation Links
* [Architecture Overview](docs/architecture.md)
* [Local Windows Setup Guide](docs/local-setup.md)
* [Oracle Cloud Deployment Guide](docs/oracle-deployment.md)
* [Cloudflare Tunnel & HTTPS Setup](docs/cloudflare-setup.md)
* [WebSocket Verification Guide](docs/websocket-testing.md)
* [Backup & Restore Procedures](docs/backup-restore.md)
* [Troubleshooting Guide](docs/troubleshooting.md)

