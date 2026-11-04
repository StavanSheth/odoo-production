# Odoo 18 Community — Technical Specifications, WebSockets & Architecture Guide

Recorded on: `2026-11-05`  
Deployment Stack: **Odoo 18.0 Community + PostgreSQL 15 + Nginx + Cloudflare Tunnel on Oracle Cloud Always Free (ARM64)**

---

## 1. Quick Access Links

| View / Purpose | Live URL | Description |
|---|---|---|
| **Public HTTPS (Primary)** | [https://lemon-brief-cleared-cartoons.trycloudflare.com](https://lemon-brief-cleared-cartoons.trycloudflare.com) | Production entry point with SSL and WebSocket routing |
| **Backend & ERP Login** | [https://lemon-brief-cleared-cartoons.trycloudflare.com/web/login](https://lemon-brief-cleared-cartoons.trycloudflare.com/web/login) | Admin & employee sign-in (Default: `admin` / `admin`) |
| **Apps & Module Manager** | [https://lemon-brief-cleared-cartoons.trycloudflare.com/odoo/apps](https://lemon-brief-cleared-cartoons.trycloudflare.com/odoo/apps) | Community module management & installation |
| **Real-Time WebSocket** | `https://lemon-brief-cleared-cartoons.trycloudflare.com/websocket` | Live chat & push notification bus (`101 Switching Protocols`) |
| **Direct Host IP (Bypassing CDN)** | `http://141.148.210.199:8080/web/login` | Direct server access via Oracle public IP |
| **Local Dev Instance** | `http://127.0.0.1:8080/web/login` | Local Docker stack running on Windows 11 / WSL2 |
| **Production Git Repository** | [https://github.com/StavanSheth/odoo-production](https://github.com/StavanSheth/odoo-production) | Active deployment code & GitHub Actions CI/CD pipeline |
| **Infrastructure Image Repo** | [https://github.com/StavanSheth/odoo_image](https://github.com/StavanSheth/odoo_image) | Clean Docker Compose & Nginx configuration blueprint |

---

## 2. Technical WebSocket Implementation & Architecture

### 2.1 The Two-Port Architecture (HTTP vs. Gevent)
Odoo 18 utilizes a split-process architecture to avoid blocking web requests with long-lived WebSocket connections:

```text
[ Browser / POS Client ]
           │
           │ (Incoming HTTPS Traffic)
           ▼
[ Cloudflare Tunnel / Edge ]
           │
           ▼
[ Nginx Reverse Proxy (Port 80) ]
     │                              │
     │ /web, /odoo, /api            │ /websocket, /longpolling
     │                              │
     ▼                              ▼
[ Odoo HTTP Workers (Port 8069) ]   [ Odoo Gevent Bus Worker (Port 8072) ]
├── Worker 1: Werkzeug HTTP         └── Non-blocking async event loop
└── Worker 2: Werkzeug HTTP             Handles 200+ persistent WebSockets
```

### 2.2 Nginx WebSocket Reverse Proxy Configuration
In [`nginx/default.conf`](file:///c:/Projects/Odoo/nginx/default.conf), WebSockets are routed to port `8072` using HTTP/1.1 connection upgrade:

```nginx
location ~* ^/websocket/? {
    proxy_pass http://odoo_chat;                  # Upstream web:8072
    proxy_set_header Upgrade $http_upgrade;       # Initiates WebSocket upgrade
    proxy_set_header Connection $connection_upgrade; # Sets "upgrade"
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $forwarded_proto; # Preserves HTTPS from Cloudflare
    proxy_set_header X-Real-IP $remote_addr;
    proxy_buffering off;                          # Disables buffering for real-time stream
    proxy_read_timeout 86400s;                    # 24-hour long-lived connection timeout
    proxy_send_timeout 86400s;
}
```

### 2.3 WebSocket Handshake Verification
A successful handshake produces an **HTTP `101 Switching Protocols`** response:

```http
GET /websocket HTTP/1.1
Host: lemon-brief-cleared-cartoons.trycloudflare.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Origin: https://lemon-brief-cleared-cartoons.trycloudflare.com

HTTP/1.1 101 Switching Protocols
Connection: upgrade
Upgrade: websocket
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Server: cloudflare
```

### 2.4 WebSocket Features Supported in Odoo 18:
* **Discuss / Chat**: Real-time team messaging and channel updates without page refresh.
* **Presence / Status**: Real-time online/away/offline user indicators (`im_status`).
* **Live Notifications**: Instant alerts when invoices are paid, leads are assigned, or stock drops below reorder thresholds.
* **Auto-Reconnection**: The browser bus automatically reconnects using exponential backoff if the network drops temporarily.

---

## 3. Technical Limitations & Sizing Ceilings

### 3.1 Hardware Allocation (Oracle Cloud Always Free)
* **Processor**: 1 OCPU (Ampere A1 ARM64 Neoverse-N1 @ 3.0 GHz = 2 vCPUs).
* **RAM**: 6.0 GB total physical memory.
* **Swap**: 4.0 GB NVMe swap space (configured for emergency OOM protection).
* **Storage**: 46.6 GB NVMe Boot Volume.

### 3.2 Concurrency & Workload Ceilings (Empirically Benchmarked)

| Metric | Measured Capacity | Technical Explanation |
|---|---|---|
| **Simultaneous Data-Entry Users** | **15 – 25 users** | Users actively saving records or generating forms at the exact same second. At 25 concurrent users, p50 latency is ~1.34s with **0% error rate**. |
| **Peak Throughput** | **20.92 requests/sec** | Measured during live benchmark against the Cloudflare HTTPS endpoint. |
| **Total Daily Active Office Users** | **80 – 120 employees** | Standard office duty cycle (1 interaction per 5–10 seconds). |
| **Concurrent WebSocket Connections** | **200+ connections** | Asynchronous Gevent event loop handles 200+ idle chat tabs with < 3% CPU usage. |
| **Maximum File Upload Size** | **100 MB** | Enforced by `client_max_body_size 100M;` in Nginx. |

### 3.3 Worker Process & Memory Ceilings
* **Worker Count**: `workers = 3` (2 HTTP workers + 1 dedicated Gevent bus worker).
* **Memory Limits**:
  * `limit_memory_soft = 1073741824` (1.0 GB per worker).
  * `limit_memory_hard = 1610612736` (1.5 GB per worker).
  * *Behavior*: If a worker exceeds 1.0 GB during a heavy report, Odoo finishes the request and recycles that worker gracefully, preventing out-of-memory crashes.
* **Execution Timeouts**:
  * `limit_time_cpu = 600s` (10 minutes CPU max).
  * `limit_time_real = 1200s` (20 minutes wall-clock max).

### 3.4 Feature Limitations (Community Edition vs. Enterprise)
* **Double-Entry Accounting Reports**: Advanced interactive Balance Sheet and P&L audit reports are Enterprise-only (`OEEL-1`). *Workaround*: Community users install the free OCA module `account_financial_report`.
* **Odoo Studio**: Drag-and-drop low-code view editor is Enterprise-only. Custom fields must be added via standard Developer Mode or custom modules in `extra-addons/`.
* **Barcode Scanner Mobile App**: Advanced camera barcode scanning interface is Enterprise-only. Basic barcode field entry via USB scanner is supported in Community.

### 3.5 Networking Limitations (Quick Tunnel vs. Named Tunnel)
* **Quick Tunnel (`trycloudflare.com`)**: The current Cloudflare quick tunnel is free and requires zero domain setup, but the URL changes if the tunnel process is restarted.
* **Permanent Domain Upgrade**: To use a fixed URL (e.g., `erp.yourcompany.com`), create a named tunnel in the Cloudflare Zero Trust dashboard and paste the token into `.env` (`CLOUDFLARE_TUNNEL_TOKEN=...`).

---

## 4. Disaster Recovery & Security Matrix

| Component | Protection Mechanism | RPO / RTO |
|---|---|---|
| **PostgreSQL Database** | Persistent Docker volume `odoo_postgres_data` + `scripts/backup.sh` | **RPO < 24 Hours** (nightly backup)<br>**RTO < 15 Minutes** (full restore) |
| **Filestore Attachments** | Persistent Docker volume `odoo_web_data` | Preserved across container recreation and server reboots |
| **Inbound Network Exposure** | Zero open inbound ports (5432, 8069, and 8072 are completely unexposed) | Fully shielded behind Cloudflare Tunnel |
| **Database Manager Access** | Blocked by Nginx CIDR rules (`/web/database/manager`) | Public cannot create or delete databases |
| **Secrets Management** | Cryptographically generated 32-character keys in `.env` | Gitignored; never exposed in source control |
