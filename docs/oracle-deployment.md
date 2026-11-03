# Oracle Cloud Infrastructure (OCI) Deployment Guide

> [!NOTE]
> Instance configuration parameters are recorded in [oci-instance-details.md](file:///c:/Projects/Odoo/docs/oci-instance-details.md).

## 1. Free-Tier Eligibility & Sizing
* **Target VM Shape**: `VM.Standard.A1.Flex` (Ampere ARM64)
* **CPUs**: 2 OCPUs (vCPUs)
* **RAM**: 12 GB RAM
* **Boot Volume**: 50 GB to 100 GB (Always Free allows up to 200 GB across tenancy)
* **Operating System**: Canonical Ubuntu 24.04 LTS (ARM64)

> [!IMPORTANT]
> Verify that the Ampere A1 shape is marked with the **"Always Free Eligible"** badge in your home region during creation.

## 2. Server Deployment Steps

### Step 1: Clone Repository
Log into your VM via SSH:
```bash
git clone <YOUR_GIT_REPO_URL> odoo18
cd odoo18
```

### Step 2: Run Deployment Script
```bash
sudo bash scripts/deploy-oci.sh
```

### Step 3: Zero-Inbound Cloudflare Tunnel Setup (Recommended)
Instead of opening ports 80/443 on your OCI VCN security lists:
1. Create a Cloudflare Tunnel in your Cloudflare Zero Trust dashboard.
2. Add the token to `.env` (`CLOUDFLARE_TUNNEL_TOKEN=...`).
3. Launch the tunnel container:
   ```bash
   docker compose --profile tunnel up -d cloudflared
   ```
4. Point the public hostname in Cloudflare to `http://nginx:80`.

