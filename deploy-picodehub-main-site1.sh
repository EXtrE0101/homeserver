#!/bin/bash
# ==============================================================================
#  Ubuntu Home Server - Deploy PiCodeHub Main to Website 1 (/site1/ & Port 8001)
# ==============================================================================
set -e

echo "=============================================================================="
echo "🥧 DEPLOYING PICODEHUB-MAIN TO WEBSITE 1 (/site1/ & PORT 8001)"
echo "=============================================================================="

SRC_DIR="/home/extre0101/picodehub-main/picodehub-main"
DEST_DIR="/var/www/site1"

if [ ! -d "$SRC_DIR" ]; then
    echo "❌ Source directory $SRC_DIR not found."
    exit 1
fi

echo "📁 [1/5] Backing up and preparing destination $DEST_DIR..."
sudo mkdir -p "$DEST_DIR"
if [ -d "$DEST_DIR" ] && [ "$(ls -A $DEST_DIR 2>/dev/null)" ]; then
    sudo mkdir -p "/var/backups/homeserver"
    sudo tar -czf "/var/backups/homeserver/site1_backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$DEST_DIR" . 2>/dev/null || true
    echo "✓ Previous Site 1 backed up."
fi

echo "📦 [2/5] Copying full PiCodeHub-Main files to $DEST_DIR (Shodh Labs Edition)..."
sudo cp -r "$SRC_DIR"/* "$DEST_DIR"/ 2>/dev/null || true
sudo cp /home/extre0101/server/.env "$DEST_DIR"/.env 2>/dev/null || true
sudo cp "$SRC_DIR"/.local* "$DEST_DIR"/ 2>/dev/null || true

# Ensure all workspace and upload directories exist
sudo mkdir -p "$DEST_DIR/user_workspace"
sudo mkdir -p "$DEST_DIR/custom_uploads"
sudo mkdir -p "$DEST_DIR/resource_uploads"
sudo mkdir -p "$DEST_DIR/projects"
sudo mkdir -p "$DEST_DIR/logs"

sudo chown -R pi:pi "$DEST_DIR" 2>/dev/null || sudo chown -R $USER:$USER "$DEST_DIR"
sudo chmod -R 775 "$DEST_DIR/user_workspace" "$DEST_DIR/custom_uploads" "$DEST_DIR/resource_uploads" "$DEST_DIR/projects" "$DEST_DIR/logs" 2>/dev/null || true

cd "$DEST_DIR"

echo "🐍 [3/5] Setting up Python virtual environment & dependencies..."
if [ ! -d "$DEST_DIR/venv" ]; then
    python3 -m venv "$DEST_DIR/venv" || true
fi

if [ -f "$DEST_DIR/venv/bin/pip" ]; then
    "$DEST_DIR/venv/bin/pip" install --upgrade pip >/dev/null 2>&1 || true
    "$DEST_DIR/venv/bin/pip" install flask gunicorn pyserial pymongo requests python-dotenv werkzeug >/dev/null 2>&1 || true
fi

echo "🔐 [4/5] Creating startup script & daemon runner (Shodh Labs Cloud)..."
cat << 'START_EOF' > "$DEST_DIR/start.sh"
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Shodh Labs Production Environment Variables
export COMPANY_NAME="Shodh Labs"
export APP_NAME="Shodh Labs Cloud Hub & IDE"
export PICODEHUB_HOST="127.0.0.1"
export PICODEHUB_PORT="5000"
export PICODEHUB_HTTPS_ONLY="true"
export PICODEHUB_TRUST_PROXY="true"
export FLASK_ENV="production"
export SECRET_KEY="shodh_labs_super_secure_master_token_2026"
export PICODEHUB_SECRET_KEY="shodh_labs_picodehub_secret_key_2026_secured"
export STORAGE_DIR="$DIR/user_workspace"
export CUSTOM_FILES_DIR="$DIR/custom_uploads"
export RESOURCE_FILES_DIR="$DIR/resource_uploads"
export PROJECTS_DIR="$DIR/projects"

if [ -f "$DIR/venv/bin/gunicorn" ]; then
    exec "$DIR/venv/bin/gunicorn" -w 4 -b 127.0.0.1:5000 --timeout 120 --access-logfile "$DIR/logs/access.log" --error-logfile "$DIR/logs/error.log" app:app
else
    exec python3 app.py
fi
START_EOF
chmod +x "$DEST_DIR/start.sh"

if which pm2 >/dev/null 2>&1; then
    pm2 delete picodehub-site1 2>/dev/null || true
    pm2 delete picodehub 2>/dev/null || true
    pm2 start "$DEST_DIR/start.sh" --name "picodehub-site1"
    pm2 save 2>/dev/null || true
fi

echo "🌐 [5/5] Configuring Nginx Reverse Proxy for Site 1 (:8001 & /site1/)..."
sudo bash -c 'cat << "SITE_EOF" > /etc/nginx/sites-available/site1
server {
    listen 8001;
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

sudo ln -sf /etc/nginx/sites-available/site1 /etc/nginx/sites-enabled/site1 2>/dev/null || true

# Update /site1/ in default config
DEFAULT_CONF="/etc/nginx/sites-available/default"
if [ -f "$DEFAULT_CONF" ]; then
    if grep -q "location /site1/" "$DEFAULT_CONF"; then
        sudo sed -i '/location \/site1\/ {/,/}/c\    location /site1/ {\n        proxy_pass http://127.0.0.1:5000/;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto $scheme;\n    }' "$DEFAULT_CONF" 2>/dev/null || true
    fi
fi

sudo nginx -t 2>/dev/null && sudo systemctl reload nginx 2>/dev/null || true

echo "=============================================================================="
echo "🎉 PiCodeHub Main is now successfully deployed to Website 1!"
echo "=============================================================================="
echo "• Worldwide Cloudflare URL: https://extre0101.github.io/homeserver/?go=site1"
echo "• Local LAN Access:         http://homeserver.local/site1/ (or :8001)"
echo "• Document Root:            $DEST_DIR"
echo "• Background Daemon:        Gunicorn 4 Workers on 127.0.0.1:5000"
echo "=============================================================================="
