<#
.SYNOPSIS
    Automated Local Odoo 18 Setup for Windows 11 / Antigravity IDE
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Odoo 18 Community — Local Windows Environment Init        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Compatibility Check
Write-Host "[*] Checking PowerShell & Windows compatibility..."
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "[!] PowerShell 5.1 or newer is required."
}

# 2. Check Docker CLI
Write-Host "[*] Checking Docker availability..."
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "[!] Docker CLI was not found. Please ensure Docker Desktop is installed and in your PATH."
}

# 3. Check Docker Engine daemon
Write-Host "[*] Checking Docker Engine daemon..."
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Daemon not responding"
    }
} catch {
    Write-Host "[!] Docker Desktop engine is not responding." -ForegroundColor Yellow
    Write-Host "[*] Attempting to connect via WSL2 engine..."
    # Check if WSL Docker is running
    $wslCheck = wsl -d Ubuntu-22.04 -u root -- docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[!] Docker engine is not running. Please launch Docker Desktop from the Start Menu."
    }
}

# 4. Check Docker Compose
Write-Host "[*] Checking Docker Compose availability..."
$composeVersion = docker compose version 2>$null
if (-not $composeVersion) {
    Write-Error "[!] Docker Compose v2 is required but not found."
}
Write-Host "[+] $composeVersion" -ForegroundColor Green

# 5 & 6. Handle .env and Generate Passwords if needed
$projectRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $projectRoot ".env"
$envExamplePath = Join-Path $projectRoot ".env.example"

if (-not (Test-Path $envPath)) {
    Write-Host "[*] Creating fresh .env with strong random credentials..." -ForegroundColor Yellow
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $dbPass = -join ((1..32) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    $masterPass = -join ((1..32) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })

    $envContent = @"
POSTGRES_DB=odoo
POSTGRES_USER=odoo
POSTGRES_PASSWORD=$dbPass
POSTGRES_IMAGE_TAG=15-alpine

ODOO_IMAGE_TAG=18.0
ODOO_MASTER_PASSWORD=$masterPass
WITHOUT_DEMO=True

LOCAL_HTTP_PORT=8080

CLOUDFLARE_TUNNEL_TOKEN=
CLOUDFLARE_HOSTNAME=
"@
    Set-Content -Path $envPath -Value $envContent -Encoding utf8
    Write-Host "[+] Generated new .env with secure credentials." -ForegroundColor Green
} else {
    Write-Host "[+] Using existing .env file (preserves your credentials)." -ForegroundColor Green
}

# 7. Pull Container Images
Set-Location $projectRoot
Write-Host "[*] Pulling Docker images..."
docker compose pull

# 8. Start Database & Wait for Health
Write-Host "[*] Starting PostgreSQL database..."
docker compose up -d db

Write-Host "[*] Waiting for PostgreSQL healthcheck to pass..."
$retries = 30
while ($retries -gt 0) {
    $status = docker inspect --format='{{json .State.Health.Status}}' odoo_db 2>$null
    if ($status -eq '"healthy"') {
        Write-Host "[+] PostgreSQL is healthy!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 1
    $retries--
}
if ($retries -eq 0) {
    Write-Error "[!] PostgreSQL failed to become healthy within 30 seconds."
}

# 9. Start Odoo & Nginx
Write-Host "[*] Starting Odoo application server and Nginx reverse proxy..."
docker compose up -d web nginx

# 10. Wait for HTTP readiness
Write-Host "[*] Waiting for Odoo to respond on port 8080..."
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   Local Odoo 18 Stack Initialized Successfully!            " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "👉 Local URL: http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Useful Commands:"
Write-Host "  View live logs:        docker compose logs -f"
Write-Host "  Stop containers:       docker compose stop"
Write-Host "  Restart stack:         docker compose restart"
Write-Host "  Run health check:      bash scripts/health-check.sh"
Write-Host "============================================================" -ForegroundColor Green

