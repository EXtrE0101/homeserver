#!/bin/bash
# ==============================================================================
#  Ubuntu Home Server - Master 1-Click Update & Apply Script
# ==============================================================================
set -e

echo "🚀 [1/4] Pulling latest repository updates from GitHub..."
cd "$(dirname "$0")"
git pull origin main

echo "🔧 [2/4] Applying Nginx Reverse Proxy for PiCodeHub (Website 1)..."
bash configure-nginx-picodehub.sh

echo "🐍 [3/4] Ensuring PiCodeHub is running with 4 Gunicorn workers..."
if [ -d "/home/extre0101/PICODEHUB/venv" ]; then
    PCH_DIR="/home/extre0101/PICODEHUB"
elif [ -d "/home/pi/PICODEHUB/venv" ]; then
    PCH_DIR="/home/pi/PICODEHUB"
else
    PCH_DIR=""
fi

if [ -n "$PCH_DIR" ] && command -v pm2 &> /dev/null; then
    pm2 stop picodehub 2>/dev/null || true
    pm2 delete picodehub 2>/dev/null || true
    pm2 start "$PCH_DIR/venv/bin/gunicorn" \
        --name "picodehub" \
        -- \
        -w 4 \
        -b 127.0.0.1:5000 \
        --timeout 120 \
        --chdir "$PCH_DIR" \
        app:app
    pm2 save
    echo "🟢 PiCodeHub is active under PM2 with 4 workers!"
fi

echo "🛡️ [4/4] Verifying Nginx and Web Services..."
sudo systemctl reload nginx
sudo python3 /usr/local/bin/sync-tunnel-gist.py 2>/dev/null || true

echo "=============================================================================="
echo "🎉 ALL CHANGES SUCCESSFULLY APPLIED TO YOUR SERVER!"
echo "=============================================================================="
echo "• Permanent Portal:     https://extre0101.github.io/homeserver/"
echo "• PiCodeHub (Site 1):   https://extre0101.github.io/homeserver/?go=site1"
echo "• WordPress cPanel:     https://extre0101.github.io/homeserver/cpanel.html"
echo "• MongoDB Control:      ./mongodb-control.sh status"
echo "=============================================================================="
