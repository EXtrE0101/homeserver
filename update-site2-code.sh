#!/bin/bash
set -e
echo "🚀 [1/3] Extracting updated PiCodeHub code to /var/www/site2/..."
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo tar -xzf "$DIR/site2-updated-bundle.tar.gz" -C /var/www/site2/
sudo chown -R pi:pi /var/www/site2/

echo "🔄 [2/3] Restarting PiCodeHub PM2 service..."
pm2 restart picodehub --update-env 2>/dev/null || pm2 start /var/www/site2/start.sh --name "picodehub"
pm2 save

echo "🌐 [3/3] Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "=============================================================================="
echo "🎉 PiCodeHub Site 2 is fully patched, CSS/JS connected, and active!"
echo "• Test URL: https://extre0101.github.io/homeserver/?go=site2"
echo "=============================================================================="
