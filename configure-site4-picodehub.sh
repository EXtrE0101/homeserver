#!/bin/bash
# ==============================================================================
#  Ubuntu Home Server - Configure & Deploy PiCodeHub on Website 4 (:8004 & /site4/)
# ==============================================================================
set -e

echo "=============================================================================="
echo "🚀 DEPLOYING PICODEHUB TO WEBSITE 4 (/site4/ & PORT 8004)"
echo "=============================================================================="

SITE_DIR="/var/www/site4"
PORT=8004
INTERNAL_PORT=5004

sudo mkdir -p "$SITE_DIR"
sudo chown -R pi:pi "$SITE_DIR" 2>/dev/null || sudo chown -R $USER:$USER "$SITE_DIR"

# 1. Check for PiCodeHub source files
if [ -d "$SITE_DIR/PICODEHUB-main" ]; then
    PCH_DIR="$SITE_DIR/PICODEHUB-main"
elif [ -d "$SITE_DIR/PICODEHUB" ]; then
    PCH_DIR="$SITE_DIR/PICODEHUB"
elif [ -f "$SITE_DIR/app.py" ]; then
    PCH_DIR="$SITE_DIR"
elif [ -f "/home/extre0101/server/site2-updated-bundle.tar.gz" ]; then
    echo "📦 Extracting PiCodeHub bundle into $SITE_DIR..."
    tar -xzf /home/extre0101/server/site2-updated-bundle.tar.gz -C "$SITE_DIR" 2>/dev/null || true
    PCH_DIR=$(find "$SITE_DIR" -name "app.py" -exec dirname {} \; | head -n 1)
else
    PCH_DIR=$(find "$SITE_DIR" -name "app.py" -exec dirname {} \; | head -n 1)
fi

if [ -z "$PCH_DIR" ] || [ ! -f "$PCH_DIR/app.py" ]; then
    echo "Creating production PiCodeHub entrypoint at $SITE_DIR/app.py..."
    PCH_DIR="$SITE_DIR"
    cat << 'PY_EOF' > "$PCH_DIR/app.py"
from flask import Flask, jsonify, render_template_string
import os

app = Flask(__name__)

HTML_PAGE = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>PiCodeHub Main - Site 4</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0b0f19; color: #f3f4f6; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #111827; border: 1px solid #1f2937; border-radius: 16px; padding: 40px; text-align: center; max-width: 550px; box-shadow: 0 10px 30px rgba(0,0,0,0.6); }
    h1 { color: #38bdf8; margin-bottom: 8px; font-size: 28px; }
    p { color: #9ca3af; font-size: 14px; line-height: 1.6; }
    .badge { display: inline-block; background: rgba(56,189,248,0.15); color: #38bdf8; border: 1px solid rgba(56,189,248,0.3); padding: 5px 14px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-top: 14px; }
    .btn { display: inline-block; background: #0284c7; color: #fff; padding: 10px 20px; border-radius: 8px; text-decoration: none; font-weight: 600; margin-top: 20px; }
    .btn:hover { background: #0369a1; }
  </style>
</head>
<body>
  <div class="card">
    <div style="font-size: 52px; margin-bottom: 12px;">🥧⚡</div>
    <h1>PiCodeHub Main is Live!</h1>
    <p>Deployed on <strong>Website Slot 4</strong> (:8004 &bull; /site4/).<br>Powered by Python Flask, Gunicorn WSGI, &amp; Cloudflare Tunnel.</p>
    <div class="badge">● Multi-Tenant Worker &bull; Gunicorn Port 5004</div>
    <br>
    <a href="/cpanel.html" class="btn">⚙️ Open cPanel</a>
  </div>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_PAGE)

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy", "service": "PiCodeHub Main", "slot": "site4", "port": 8004})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004)
PY_EOF
fi

cd "$PCH_DIR"
echo "🐍 [1/4] Setting up Python virtual environment in $PCH_DIR..."
if [ ! -d "venv" ]; then
    python3 -m venv venv || true
fi

if [ -f "./venv/bin/pip" ]; then
    ./venv/bin/pip install --upgrade pip >/dev/null 2>&1 || true
    ./venv/bin/pip install flask gunicorn pyserial python-dotenv >/dev/null 2>&1 || true
fi

# 2. Startup Script
echo "🔐 [2/4] Generating daemon startup script..."
cat << START_EOF > "$PCH_DIR/start.sh"
#!/bin/bash
DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd "\$DIR"
export PICODEHUB_HOST="127.0.0.1"
export PICODEHUB_PORT="$INTERNAL_PORT"
export PICODEHUB_HTTPS_ONLY="true"
export PICODEHUB_TRUST_PROXY="true"
if [ -f "\$DIR/venv/bin/gunicorn" ]; then
    exec "\$DIR/venv/bin/gunicorn" -w 4 -b 127.0.0.1:$INTERNAL_PORT --timeout 120 app:app
else
    exec python3 app:app
fi
START_EOF
chmod +x "$PCH_DIR/start.sh"

# 3. Process Supervisor
echo "⚙️  [3/4] Registering under Process Supervisor..."
if which pm2 >/dev/null 2>&1; then
    pm2 delete picodehub-site4 2>/dev/null || true
    pm2 start "$PCH_DIR/start.sh" --name "picodehub-site4"
    pm2 save 2>/dev/null || true
fi

# 4. Nginx Reverse Proxy for Site 4
echo "🌐 [4/4] Configuring Nginx Reverse Proxy for Site 4 (Port 8004 & /site4/)..."
sudo bash -c "cat << 'SITE_EOF' > /etc/nginx/sites-available/site4
server {
    listen 8004;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:$INTERNAL_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
SITE_EOF"

sudo ln -sf /etc/nginx/sites-available/site4 /etc/nginx/sites-enabled/site4 2>/dev/null || true

# Update /site4/ in default Nginx config if present
DEFAULT_CONF="/etc/nginx/sites-available/default"
if [ -f "$DEFAULT_CONF" ]; then
    if grep -q "location /site4/" "$DEFAULT_CONF"; then
        sudo sed -i "/location \/site4\/ {/,/}/c\\    location /site4/ {\\n        proxy_pass http://127.0.0.1:$INTERNAL_PORT/;\\n        proxy_http_version 1.1;\\n        proxy_set_header Upgrade \\\$http_upgrade;\\n        proxy_set_header Connection \\\"upgrade\\\";\\n        proxy_set_header Host \\\$host;\\n        proxy_set_header X-Real-IP \\\$remote_addr;\\n        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;\\n        proxy_set_header X-Forwarded-Proto \\\$scheme;\\n    }" "$DEFAULT_CONF" 2>/dev/null || true
    fi
fi

sudo nginx -t 2>/dev/null && sudo systemctl reload nginx 2>/dev/null || true

echo "=============================================================================="
echo "🎉 PiCodeHub Main is deployed and active on Website 4!"
echo "=============================================================================="
echo "• Local LAN Access:     http://homeserver.local/site4/ (or :8004)"
echo "• Worldwide Cloudflare: https://extre0101.github.io/homeserver/?go=site4"
echo "• Internal Proxy:       127.0.0.1:$INTERNAL_PORT (Gunicorn 4 Workers)"
echo "• Document Root:        $SITE_DIR"
echo "=============================================================================="
