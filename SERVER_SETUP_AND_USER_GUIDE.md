# 📖 Complete Home Server Setup & User Guide

This guide documents the full architecture, configurations, credentials, security measures, failsafe mechanisms, and daily operations for your **Ubuntu Home Server**.

---

## 📑 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Hardware & OS Configuration](#2-hardware--os-configuration)
3. [Local Domain (`homeserver.local`) & LAN Access](#3-local-domain-homeserverlocal--lan-access)
4. [Web Server & Multi-Site Setup (Nginx)](#4-web-server--multi-site-setup-nginx)
5. [Independent MongoDB Multi-Database Suite](#5-independent-mongodb-multi-database-suite)
6. [WordPress-Style Web cPanel & File Manager](#6-wordpress-style-web-cpanel--file-manager)
7. [Web Terminal (ttyd)](#7-web-terminal-ttyd)
8. [System Dashboard (Cockpit)](#8-system-dashboard-cockpit)
9. [Cloudflare Tunnel & Worldwide Access](#9-cloudflare-tunnel--worldwide-access)
10. [Automated Maintenance & Downtime Failsafe](#10-automated-maintenance--downtime-failsafe)
11. [Security & Firewall Hardening](#11-security--firewall-hardening)
12. [SSH & Terminal Access Methods](#12-ssh--terminal-access-methods)
13. [Deploying Websites & Web Apps](#13-deploying-websites--web-apps)
14. [Multi-Layer Failsafe & Self-Healing Architecture](#14-multi-layer-failsafe--self-healing-architecture)
15. [Essential Commands Cheat Sheet](#15-essential-commands-cheat-sheet)
16. [Troubleshooting & Maintenance](#16-troubleshooting--maintenance)

---

## 1. Architecture Overview

Your repurposed laptop operates as a dedicated **24/7 Home Server** capable of running multiple websites, isolated databases, backend applications, and management tools simultaneously:

```
                  [ Internet (Worldwide) ]
                             │
                  [ Cloudflare Tunnel ] (HTTPS / TLS)
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
            ├─► MongoDB Community (Port 27017)│
            │   ├─► site1_db  -> Website 1 DB │
            │   ├─► site2_db  -> Website 2 DB │
            │   ├─► site3_db  -> Website 3 DB │
            │   ├─► site4_db  -> Website 4 DB │
            │   └─► admin     -> Master Auth  │
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

## 5. Independent MongoDB Multi-Database Suite

Each hosted website has its own **isolated, independent database** with dedicated user permissions:

| Website | Database Name | Dedicated User | Connection URI |
| :--- | :--- | :--- | :--- |
| **Website 1** | `site1_db` | `site1_user` | `mongodb://site1_user:Site1@123@localhost:27017/site1_db` |
| **Website 2** | `site2_db` | `site2_user` | `mongodb://site2_user:Site2@123@localhost:27017/site2_db` |
| **Website 3** | `site3_db` | `site3_user` | `mongodb://site3_user:Site3@123@localhost:27017/site3_db` |
| **Website 4** | `site4_db` | `site4_user` | `mongodb://site4_user:Site4@123@localhost:27017/site4_db` |
| **Master Admin** | `admin` | `admin` | `mongodb://admin:Sanchit@123@localhost:27017/admin` |

### 5.1 On / Off Control Switch
You can toggle MongoDB master services or per-site databases using:
1. **WordPress cPanel UI**: Open the **🍃 MongoDB Multi-DB** tab in [`cpanel.html`](file:///home/extre0101/server/cpanel.html) and toggle the switches.
2. **Terminal CLI Control**:
   ```bash
   ./mongodb-control.sh status    # Check live status of all 4 DBs
   ./mongodb-control.sh on        # Turn Master MongoDB ON
   ./mongodb-control.sh off       # Turn Master MongoDB OFF
   ./mongodb-control.sh restart   # Restart MongoDB daemon
   ```

### 5.2 Initial Automated Setup Script
To install MongoDB Community Server and initialize all 4 isolated databases in one click:
```bash
bash setup-mongodb.sh
```

---

## 6. WordPress-Style Web cPanel & File Manager

A web-based **cPanel** runs at `cpanel.html` and FileBrowser engine at `/panel/` with isolated logins:

| Account | Username | Password | Accessible Path | Role |
| :--- | :--- | :--- | :--- | :--- |
| **Master Admin** | `admin` | `[YOUR_MASTER_PASSWORD]` | `/var/www/` | Manages all sites, databases & settings |
| **Website 1** | `site1` | `[SITE_1_PASSWORD]` | `/var/www/site1/` | Website 1 files & editor |
| **Website 2** | `site2` | `[SITE_2_PASSWORD]` | `/var/www/site2/` | Website 2 files & editor |
| **Website 3** | `site3` | `[SITE_3_PASSWORD]` | `/var/www/site3/` | Website 3 files & editor |
| **Website 4** | `site4` | `[SITE_4_PASSWORD]` | `/var/www/site4/` | Website 4 files & editor |

---

## 7. Web Terminal (ttyd)

Self-hosted web terminal running directly on your server via `ttyd.service` at `/terminal/`:
* **Login**: User `pi` / Master Password
* High-speed, WebSocket-powered interactive shell in any browser with zero third-party relay lag.

---

## 8. System Dashboard (Cockpit)

* **Local LAN URL**: `https://homeserver.local:9090` (or `https://192.168.150.101:9090`)
* **Username**: `pi` | **Password**: `[YOUR_MASTER_PASSWORD]`
* Full hardware graphs, service manager, storage partitioning, and system logs.

---

## 9. Cloudflare Tunnel & Worldwide Access

### 9.1 Permanent Auto-Updating Portal (GitHub Pages)
A dedicated, permanent web portal hosted on GitHub Pages that dynamically fetches the latest live Cloudflare tunnel URL from your GitHub Gist:

* **Permanent Hub Link**: [https://extre0101.github.io/homeserver/](https://extre0101.github.io/homeserver/)
* **Direct Web Terminal**: [https://extre0101.github.io/homeserver/?go=terminal](https://extre0101.github.io/homeserver/?go=terminal)
* **Direct Web cPanel**: [https://extre0101.github.io/homeserver/?go=panel](https://extre0101.github.io/homeserver/?go=panel)
* **Direct Website 1**: [https://extre0101.github.io/homeserver/?go=site1](https://extre0101.github.io/homeserver/?go=site1)
* **Direct Website 2**: [https://extre0101.github.io/homeserver/?go=site2](https://extre0101.github.io/homeserver/?go=site2)
* **Direct Website 3**: [https://extre0101.github.io/homeserver/?go=site3](https://extre0101.github.io/homeserver/?go=site3)
* **Direct Website 4**: [https://extre0101.github.io/homeserver/?go=site4](https://extre0101.github.io/homeserver/?go=site4)
* **Manual Portal Menu**: [https://extre0101.github.io/homeserver/?pause=1](https://extre0101.github.io/homeserver/?pause=1)

---

## 10. Automated Maintenance & Downtime Failsafe

When the server is rebooting, applying updates, or temporarily offline:
* **Zero Broken Error Screens**: The portal automatically enters **🛠️ System Maintenance Mode**.
* **Live Polling Countdown**: Automatically re-checks connection every 10 seconds.
* **Instant Auto-Forward**: As soon as the server comes online, the user is forwarded seamlessly without refreshing.

---

## 11. Security & Firewall Hardening

* **UFW Firewall**: Default deny incoming; allows `80`, `8001:8004`, `9090`, `5353`; rate-limits `22`.
* **MongoDB Security**: Binds exclusively to `127.0.0.1:27017` with authentication enabled. Port 27017 is never directly exposed to the open internet.
* **Fail2ban**: Automatically bans IP addresses attempting SSH brute-force attacks.
* **File Permissions**: Directories locked to `755`, files to `644`, owned by `pi:pi`.

---

## 12. SSH & Terminal Access Methods

1. **Web Terminal (Worldwide)**: Open `/terminal/` on your Cloudflare link &rarr; log in with user `pi` & master password.
2. **Local SSH**: `ssh pi@homeserver.local` (Enter configured master password).
3. **Cockpit Web Console**: Open `https://homeserver.local:9090` &rarr; click **Terminal**.

---

## 13. Deploying Websites & Web Apps

* **Static HTML/CSS/JS**: Open `/panel/` &rarr; log in as `site1` &rarr; drag and drop files.
* **Git Clone**: `cd /var/www/site1 && git clone <repo-url> .`
* **Node.js + MongoDB**:
  ```javascript
  const mongoose = require('mongoose');
  mongoose.connect('mongodb://site1_user:Site1%40123@127.0.0.1:27017/site1_db');
  ```
* **PM2 Process Manager**: `pm2 start server.js --name "site1" && pm2 save`

---

## 14. Multi-Layer Failsafe & Self-Healing Architecture

```
[ Layer 1: Self-Healing Watchdog ] ──► Auto-restarts dead services & Wi-Fi every 2 min
[ Layer 2: Wi-Fi Power-Lock      ] ──► Wi-Fi sleep mode disabled (24/7 radio active)
[ Layer 3: Local Network (mDNS)  ] ──► homeserver.local / 192.168.150.107 always works on LAN
[ Layer 4: Physical Hardware     ] ──► Plug Ethernet cable or open laptop lid for direct TTY
[ Layer 5: Memory & Swap Guard   ] ──► 3.6 GB swap space absorbs spikes without kernel freeze
```

---

## 15. Essential Commands Cheat Sheet

```bash
# Check service status
sudo systemctl status nginx mongod filebrowser ttyd quicktunnel cockpit.socket fail2ban

# MongoDB Control
./mongodb-control.sh status
./mongodb-control.sh on
./mongodb-control.sh off

# Check active Cloudflare URL
journalctl -u quicktunnel.service -n 20 --no-pager | grep -o 'https://.*trycloudflare.com'

# Restart all services
sudo systemctl restart nginx mongod filebrowser ttyd quicktunnel
```

---

## 16. Troubleshooting & Maintenance

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Website shows 404** | Missing `index.html` in site folder | Upload an `index.html` file into `/var/www/siteX/`. |
| **Portal shows Maintenance** | Server rebooting or tunnel syncing | Wait 10s or run `./mongodb-control.sh status` and check tunnel. |
| **MongoDB connection refused** | Daemon stopped | Run `./mongodb-control.sh on` or `sudo systemctl start mongod`. |
| **cPanel shows Permission Denied** | Files owned by root | Run `sudo chown -R pi:pi /var/www`. |

---

*Guide generated for Ubuntu Home Server (`homeserver.local`).*
