# Local Setup Guide (Windows 11 / WSL2)

## Prerequisites
* Windows 11 with **Docker Desktop** installed (WSL2 backend enabled).
* Antigravity IDE terminal or PowerShell 5.1+.

## Automated Quick Start
Run from PowerShell in the project root:
```powershell
.\scripts\init-local.ps1
```

Or from bash / WSL:
```bash
bash scripts/init-local.sh
```

## Accessing Odoo
* **URL**: [http://localhost:8080](http://localhost:8080)
* **Master Password**: Found in your `.env` file under `ODOO_MASTER_PASSWORD`.

## Useful Commands
```powershell
# View logs
docker compose logs -f

# Check health
bash scripts/health-check.sh

# Stop containers
docker compose stop

# Restart stack
docker compose restart
```

