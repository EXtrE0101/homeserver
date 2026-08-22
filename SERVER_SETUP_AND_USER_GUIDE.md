# 📖 Complete Home Server Setup & User Guide

This guide documents the full architecture, configurations, credentials, security measures, failsafe mechanisms, and daily operations for your **Ubuntu Home Server**.

---

## 📑 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Hardware & OS Configuration](#2-hardware--os-configuration)
3. [Local Domain (`homeserver.local`) & LAN Access](#3-local-domain-homeserverlocal--lan-access)
4. [Web Server & Multi-Site Setup (Nginx)](#4-web-server--multi-site-setup-nginx)
5. [Web cPanel & File Manager](#5-web-cpanel--file-manager)
6. [Web Terminal (ttyd)](#6-web-terminal-ttyd)
7. [System Dashboard (Cockpit)](#7-system-dashboard-cockpit)
8. [Cloudflare Tunnel & Worldwide Access](#8-cloudflare-tunnel--worldwide-access)
9. [Security & Firewall Hardening](#9-security--firewall-hardening)
10. [SSH & Terminal Access Methods](#10-ssh--terminal-access-methods)
11. [Deploying Websites & Web Apps](#11-deploying-websites--web-apps)
12. [Multi-Layer Failsafe & Self-Healing Architecture](#12-multi-layer-failsafe--self-healing-architecture)
13. [Essential Commands Cheat Sheet](#13-essential-commands-cheat-sheet)
14. [Troubleshooting & Maintenance](#14-troubleshooting--maintenance)

---

## 1. Architecture Overview

Your repurposed laptop operates as a dedicated **24/7 Home Server** capable of running multiple websites, backend applications, and management tools simultaneously:

```
                  [ Internet (Worldwide) ]
                             │
                  [ Cloudflare Tunnel ] (HTTPS / SSL)
                             │
            ┌────────────────┴────────────────┐
            │       Ubuntu Home Server        │
            │  (192.168.150.101 / homeserver) │
            │                                 │
            ├─► Nginx Web Server (Port 80)    │
            │   ├─► /         -> Main Hub     │
            │   ├─► /site1/   -> Website 1    │
            │   ├─► /site2/   -> Website 2    │
            │   ├─► /site3/   -> Website 3    │
            │   ├─► /site4/   -> Website 4    │
            │   ├─► /panel/   -> Web cPanel   │
            │   └─► /terminal/-> Web Terminal │
            │                                 │
            ├─► Standalone Ports:             │
            │   ├─► 8001 (Site 1)             │
            │   ├─► 8002 (Site 2)             │
            │   ├─► 8003 (Site 3)             │
            │   ├─► 8004 (Site 4)             │
            │   ├─► 7681 (ttyd Terminal)      │
            │   └─► 8080 (FileBrowser cPanel) │
            │                                 │
            ├─► Cockpit Console (Port 9090)   │
            ├─► PM2 (Node.js/Python Apps)     │
            ├─► Avahi mDNS (homeserver.local) │
            ├─► UFW Firewall (Rate-Limited)   │
            ├─► Fail2ban (SSHD Jail)          │
            ├─► Self-Healing Watchdog Timer   │
            └─► SSH Server (Port 22)          │
```

---

## 2. Hardware & OS Configuration

* **Full Disk Utilization (~300 GB)**: Root LVM partition extended to 100% of physical capacity:
  ```bash
  sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv -r
  ```
* **24/7 Power**: `HandleLidSwitch=ignore` configured and sleep/suspend masked. The laptop lid can stay closed 24/7.
* **Instant Auto-Boot**: GRUB `timeout=0` set for instant restart without waiting for a keyboard:
  ```ini
  GRUB_TIMEOUT=0
  GRUB_TIMEOUT_STYLE=hidden
  GRUB_RECORDFAIL_TIMEOUT=0
  ```

---

## 3. Local Domain (`homeserver.local`) & LAN Access

Thanks to **Avahi mDNS**, you don't need to remember the IP address on your home Wi-Fi:

* **Main Hub**: `http://homeserver.local`
* **Web Terminal**: `http://homeserver.local/terminal/`
* **Web cPanel**: `http://homeserver.local/panel/`
* **Cockpit**: `https://homeserver.local:9090`
* **Local SSH**: `ssh pi@homeserver.local`

---

## 4. Web Server & Multi-Site Setup (Nginx)

| Site | Folder on Server | Local Port | Path URL |
| :--- | :--- | :--- | :--- |
| **Main Hub** | `/var/www/html/` | `80` | `/` |
| **Website 1** | `/var/www/site1/` | `8001` | `/site1/` |
| **Website 2** | `/var/www/site2/` | `8002` | `/site2/` |
| **Website 3** | `/var/www/site3/` | `8003` | `/site3/` |
| **Website 4** | `/var/www/site4/` | `8004` | `/site4/` |

---

## 5. Web cPanel & File Manager

A web-based **cPanel** (FileBrowser engine) runs as `filebrowser.service` at `/panel/` with isolated logins:

| Account | Username | Password | Accessible Path | Role |
| :--- | :--- | :--- | :--- | :--- |
| **Master Admin** | `admin` | `[YOUR_MASTER_PASSWORD]` | `/var/www/` | Manages all sites, users & settings |
| **Website 1** | `site1` | `[SITE_1_PASSWORD]` | `/var/www/site1/` | Website 1 files & editor |
| **Website 2** | `site2` | `[SITE_2_PASSWORD]` | `/var/www/site2/` | Website 2 files & editor |
| **Website 3** | `site3` | `[SITE_3_PASSWORD]` | `/var/www/site3/` | Website 3 files & editor |
| **Website 4** | `site4` | `[SITE_4_PASSWORD]` | `/var/www/site4/` | Website 4 files & editor |

---

## 6. Web Terminal (ttyd)

Self-hosted web terminal running directly on your server via `ttyd.service` at `/terminal/`:
* **Login**: User `pi` / Master Password
* High-speed, WebSocket-powered interactive shell in any browser with zero third-party relay lag.

---

## 7. System Dashboard (Cockpit)

* **Local LAN URL**: `https://homeserver.local:9090` (or `https://192.168.150.101:9090`)
* **Username**: `pi` | **Password**: `[YOUR_MASTER_PASSWORD]`
* Full hardware graphs, service manager, storage partitioning, and system logs.

---

## 8. Worldwide Access & Auto-Updating Links

### 8.1 Permanent Auto-Updating Portal (GitHub Pages)
A dedicated, permanent web portal hosted on GitHub Pages that dynamically fetches the latest live Cloudflare tunnel URL from your GitHub Gist in under 200ms:

* **Permanent Hub Link**: [https://extre0101.github.io/homeserver/](https://extre0101.github.io/homeserver/)
* **Direct Web Terminal**: [https://extre0101.github.io/homeserver/?go=terminal](https://extre0101.github.io/homeserver/?go=terminal)
* **Direct Web cPanel**: [https://extre0101.github.io/homeserver/?go=panel](https://extre0101.github.io/homeserver/?go=panel)
* **Direct Website 1**: [https://extre0101.github.io/homeserver/?go=site1](https://extre0101.github.io/homeserver/?go=site1)
* **Direct Website 2**: [https://extre0101.github.io/homeserver/?go=site2](https://extre0101.github.io/homeserver/?go=site2)
* **Direct Website 3**: [https://extre0101.github.io/homeserver/?go=site3](https://extre0101.github.io/homeserver/?go=site3)
* **Direct Website 4**: [https://extre0101.github.io/homeserver/?go=site4](https://extre0101.github.io/homeserver/?go=site4)
* **Manual Portal Menu**: [https://extre0101.github.io/homeserver/?pause=1](https://extre0101.github.io/homeserver/?pause=1)

### 8.2 Dynamic Discovery via GitHub Gist & Blog Widget
Whenever the server reboots and generates a new tunnel URL, the background script `/usr/local/bin/sync-tunnel-gist.py` automatically updates your secret GitHub Gist.

* **Live JSON Endpoint**: `https://gist.githubusercontent.com/EXtrE0101/4e368fcb25106cbf65820b452e874419/raw/server.json`
* **GitHub Gist**: [https://gist.github.com/EXtrE0101/4e368fcb25106cbf65820b452e874419](https://gist.github.com/EXtrE0101/4e368fcb25106cbf65820b452e874419)
* **Portal GitHub Repository**: [https://github.com/EXtrE0101/homeserver](https://github.com/EXtrE0101/homeserver)
* **Blog Button & Widget**: Available in [`blog-server-widget.html`](file:///home/extre0101/server/blog-server-widget.html).

### 8.3 Current Direct Cloudflare Tunnel (Rotates on reboot)
* **Direct Hub Link**: [https://colleague-encountered-identification-solely.trycloudflare.com](https://colleague-encountered-identification-solely.trycloudflare.com)

---

## 9. Security & Firewall Hardening

* **UFW Firewall**: Default deny incoming; allows `80`, `8001:8004`, `9090`, `5353`; rate-limits `22`.
* **Fail2ban**: Automatically bans IP addresses attempting SSH brute-force attacks.
* **File Permissions**: Directories locked to `755`, files to `644`, owned by `pi:pi`.

---

## 10. SSH & Terminal Access Methods

1. **Web Terminal (Worldwide)**: Open `/terminal/` on your Cloudflare link &rarr; log in with user `pi` & master password.
2. **Local SSH**: `ssh pi@homeserver.local` (Enter configured master password).
3. **Cockpit Web Console**: Open `https://homeserver.local:9090` &rarr; click **Terminal**.

---

## 11. Deploying Websites & Web Apps

* **Static HTML/CSS/JS**: Open `/panel/` &rarr; log in as `site1` &rarr; drag and drop files.
* **Git Clone**: `cd /var/www/site1 && git clone <repo-url> .`
* **Node.js**: `cd /var/www/site1 && npm install && pm2 start server.js --name "site1" && pm2 save`
* **Python**: `cd /var/www/site2 && python3 -m venv venv && source venv/bin/activate && pm2 start "python3 app.py" --name "site2" && pm2 save`

---

## 12. Multi-Layer Failsafe & Self-Healing Architecture

```
[ Layer 1: Self-Healing Watchdog ] ──► Auto-restarts dead services & Wi-Fi every 2 min
[ Layer 2: Wi-Fi Power-Lock      ] ──► Wi-Fi sleep mode disabled (24/7 radio active)
[ Layer 3: Local Network (mDNS)  ] ──► homeserver.local / 192.168.150.107 always works on LAN
[ Layer 4: Physical Hardware     ] ──► Plug Ethernet cable or open laptop lid for direct TTY
[ Layer 5: Memory & Swap Guard   ] ──► 3.6 GB swap space absorbs spikes without kernel freeze
```

1. **Automated Self-Healing Watchdog (`server-watchdog.timer`)**: Runs every 2 minutes. Restarts any stopped services and reconnects Wi-Fi if dropped.
2. **Wi-Fi Power-Save Disabled (`wifi.powersave=2`)**: Prevents Wi-Fi adapter from sleeping.
3. **Local Access Failsafe**: `homeserver.local` works independently of Cloudflare or internet status.
4. **Physical Failsafe**: Direct Ethernet connection or open laptop lid for direct console.
5. **Memory Failsafe**: 3.6 GB swap partition prevents kernel lockups.

---

## 13. Essential Commands Cheat Sheet

```bash
# Check service status
sudo systemctl status nginx filebrowser ttyd quicktunnel cockpit.socket fail2ban server-watchdog.timer

# Check active Cloudflare URL
journalctl -u quicktunnel.service -n 20 --no-pager | grep -o 'https://.*trycloudflare.com'

# Restart all services
sudo systemctl restart nginx filebrowser ttyd quicktunnel
```

---

## 14. Troubleshooting & Maintenance

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Website shows 404** | Missing `index.html` in site folder | Upload an `index.html` file into `/var/www/siteX/`. |
| **cPanel shows Permission Denied** | Files owned by root | Run `sudo chown -R pi:pi /var/www`. |
| **Cockpit shows SSL warning** | Self-signed local certificate | Click **Advanced** &rarr; **Proceed to homeserver.local (unsafe)**. |
| **Check new tunnel link after restart** | Quick tunnel generated new URL | Run `journalctl -u quicktunnel.service -n 20 --no-pager \| grep -o 'https://.*trycloudflare.com'`. |

---

*Guide generated for Ubuntu Home Server (`homeserver.local`).*
