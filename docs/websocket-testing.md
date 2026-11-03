# WebSocket Verification & Testing Guide

## Why WebSocket Testing Is Critical
In Odoo 18, Discuss, real-time messaging, user presence indicators, and live dashboard metrics communicate over WebSockets on route `/websocket`.
A page loading over HTTP does **not** prove WebSockets are functioning.

---

## 1. Automated CLI Verification

Run the automated health check:
```bash
bash scripts/health-check.sh http://127.0.0.1:8080
```
This script sends an RFC 6455 compliant WebSocket upgrade handshake with a base64 key:
```bash
curl -m 5 -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Host: 127.0.0.1" \
  -H "Origin: http://127.0.0.1:8080" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  http://127.0.0.1:8080/websocket
```
**Expected Response**:
```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
```

---

## 2. Browser Verification (Chrome DevTools)

1. Open `http://localhost:8080` (or your public Cloudflare HTTPS URL).
2. Press `F12` to open Developer Tools.
3. Switch to the **Network** tab and filter by **WS** (WebSockets).
4. Refresh the page or click into the **Discuss** app.
5. Look for the request named `websocket`:
   * **Status Code**: `101 Switching Protocols`.
   * Click into **Messages**: You should see periodic JSON heartbeat frames (`["bus.bus", ...]`).
6. **Reconnection Test**:
   * Temporarily disconnect your network or restart containers: `docker compose restart web`.
   * Notice Odoo UI shows a yellow reconnecting toast, then automatically reconnects with a fresh 101 status.

