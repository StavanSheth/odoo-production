#!/usr/bin/env bash
# =============================================================================
# Automated Docker & Docker Compose Installer
# Supports Ubuntu 22.04/24.04, Debian, and Oracle Linux (x86_64 and ARM64)
# =============================================================================
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[!] Please run as root or with sudo: sudo bash scripts/setup-docker.sh"
  exit 1
fi

echo "============================================================"
echo " Docker & Docker Compose Engine Installer"
echo "============================================================"

if command -v docker &> /dev/null && docker compose version &> /dev/null; then
  echo "[+] Docker and Docker Compose are already installed and up to date."
  docker --version
  docker compose version
  exit 0
fi

echo "[*] Installing official Docker engine via get.docker.com..."
curl -fsSL https://get.docker.com | sh

systemctl enable docker
systemctl start docker

# Ensure current sudo user is in docker group if SUDO_USER is set
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker "$SUDO_USER"
  echo "[+] Added $SUDO_USER to docker group."
fi

echo "[+] Docker installation complete:"
docker --version
docker compose version

