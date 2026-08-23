#!/bin/bash
# ==============================================================================
#  Configure & Launch Shodh Labs on Website 2 (/site2/ & Port 8002)
# ==============================================================================
set -e

echo "🔧 [1/4] Setting folder permissions for Site 2..."
sudo chown -R pi:pi /var/www/site2

# Determine exact directory
if [ -d "/var/www/site2/SHODH_LABS-main" ]; then
    PCH_DIR="/var/www/site2/SHODH_LABS-main"
elif [ -d "/var/www/site2/SHODH_LABS" ]; then
    PCH_DIR="/var/www/site2/SHODH_LABS"
elif [ -f "/var/www/site2/app.py" ]; then
    PCH_DIR="/var/www/site2"
else
    # Find any folder containing app.py inside /var/www/site2
    PCH_DIR=$(find /var/www/site2 -name "app.py" -exec dirname {} \; | head -n 1)
fi

if [ -z "$PCH_DIR" ] || [ ! -f "$PCH_DIR/app.py" ]; then
    echo "❌ Error: Could not find app.py inside /var/www/site2/."
    echo "Please make sure your files or ZIP are extracted inside /var/www/site2/."
    exit 1
fi

echo "📂 Shodh Labs located at: $PCH_DIR"
cd "$PCH_DIR"

echo "🐍 [2/4] Setting up Python Virtual Environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
./venv/bin/pip install --upgrade pip
./venv/bin/pip install flask gunicorn pyserial python-dotenv

echo "🔐 [3/4] Creating startup script & security keys..."
cat << 'START_EOF' > start.sh
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
export SHODH_LABS_PASSWORD="Sanchit@123"
export SHODH_LABS_SECRET_KEY="Shodh Labs_SecretKey_Site2_Secured_2026"
export SHODH_LABS_HOST="127.0.0.1"
export SHODH_LABS_HTTPS_ONLY="true"
export SHODH_LABS_TRUST_PROXY="true"
exec "$DIR/venv/bin/gunicorn" -w 4 -b 127.0.0.1:5000 --timeout 120 app:app
START_EOF

chmod +x start.sh

# Start or restart under PM2
pm2 delete shodhlabs 2>/dev/null || true
pm2 start ./start.sh --name "shodhlabs"
pm2 save

echo "🔧 [4/4] Configuring Nginx Reverse Proxy for Site 2 (Port 8002 & /site2/)..."
sudo bash -c 'cat << "SITE_EOF" > /etc/nginx/sites-available/site2
server {
    listen 8002;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
SITE_EOF'

sudo ln -sf /etc/nginx/sites-available/site2 /etc/nginx/sites-enabled/site2

# Update /site2/ in default Nginx config
DEFAULT_CONF="/etc/nginx/sites-available/default"
if [ -f "$DEFAULT_CONF" ]; then
    if grep -q "location /site2/" "$DEFAULT_CONF"; then
        sudo sed -i '/location \/site2\/ {/,/}/c\    location /site2/ {\n        proxy_pass http://127.0.0.1:5000/;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto $scheme;\n    }' "$DEFAULT_CONF"
    fi
fi

sudo nginx -t && sudo systemctl reload nginx

echo "=============================================================================="
echo "🎉 Shodh Labs is now LIVE on Website 2 (/site2/ & Port 8002)!"
echo "=============================================================================="
echo "• Worldwide Link:     https://extre0101.github.io/homeserver/?go=site2"
echo "• Local LAN Access:    http://homeserver.local/site2/ (or :8002)"
echo "• PM2 Process:        pm2 status shodhlabs"
echo "=============================================================================="
