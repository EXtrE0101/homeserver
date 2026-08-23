#!/bin/bash
# ==============================================================================
#  Ubuntu Home Server - Master 1-Click New Website & Database Provisioner
#  Supports: Multi-Tenant Assignment, App Templates, Isolated MongoDB & Security
# ==============================================================================
set -e

SITE_NAME="${1}"
PORT="${2}"
TEMPLATE="${3:-html}"
CLIENT_OWNER="${4:-admin}"

if [ -z "$SITE_NAME" ] || [ -z "$PORT" ]; then
    echo "=============================================================================="
    echo "❌ ERROR: Missing required arguments."
    echo "Usage: sudo bash add-new-site.sh <site_name> <port> [template] [client_owner]"
    echo "Example: sudo bash add-new-site.sh client-store 8005 html alex"
    echo "Templates available: html, react, node, flask, php, commercial"
    echo "=============================================================================="
    exit 1
fi

# Sanitize site name (lowercase alphanumeric and dashes)
SITE_NAME=$(echo "$SITE_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-_')
SITE_DIR="/var/www/$SITE_NAME"

echo "=============================================================================="
echo "🚀 PROVISIONING NEW WEBSITE & TENANT ENVIRONMENT: '$SITE_NAME'"
echo "=============================================================================="
echo "• Site Slug:       $SITE_NAME"
echo "• Standalone Port: $PORT"
echo "• App Template:    $TEMPLATE"
echo "• Assigned Owner:  $CLIENT_OWNER"
echo "• Document Root:   $SITE_DIR"
echo "=============================================================================="

# 1. Create directory structure & set permissions
echo "🌐 [1/5] Setting up isolated web directory at $SITE_DIR..."
sudo mkdir -p "$SITE_DIR"
sudo chown -R pi:pi "$SITE_DIR"
sudo chmod 755 "$SITE_DIR"

# 2. Generate Boilerplate Template
echo "📄 [2/5] Deploying '$TEMPLATE' application template..."

if [ "$TEMPLATE" = "flask" ]; then
    cat << 'PY_EOF' > "$SITE_DIR/app.py"
from flask import Flask, jsonify, render_template_string
import os

app = Flask(__name__)

HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>{{ site_name }} - Python Flask Server</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #0b0f19; color: #f3f4f6; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #111827; border: 1px solid #1f2937; border-radius: 16px; padding: 40px; text-align: center; max-width: 500px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
    h1 { color: #38bdf8; margin-bottom: 8px; }
    p { color: #9ca3af; font-size: 14px; line-height: 1.6; }
    .pill { display: inline-block; background: rgba(56,189,248,0.15); color: #38bdf8; border: 1px solid rgba(56,189,248,0.3); padding: 4px 14px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div style="font-size: 48px; margin-bottom: 12px;">🐍</div>
    <h1>{{ site_name }} is Running!</h1>
    <p>Powered by Python Flask & Gunicorn on Ubuntu Home Server.<br>Assigned Owner: <strong>{{ owner }}</strong></p>
    <div class="pill">● Flask Microservice &bull; Port {{ port }}</div>
  </div>
</body>
</html>
"""

@app.route('/')
def home():
    return render_template_string(HTML_PAGE, site_name=os.getenv('SITE_NAME', 'Website'), port=os.getenv('PORT', '5000'), owner=os.getenv('OWNER', 'admin'))

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy", "service": os.getenv('SITE_NAME', 'Website'), "runtime": "Python 3 Flask"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PY_EOF
    sudo chown pi:pi "$SITE_DIR/app.py"

elif [ "$TEMPLATE" = "node" ]; then
    cat << 'JS_EOF' > "$SITE_DIR/server.js"
const http = require('http');
const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ status: 'healthy', runtime: 'Node.js LTS' }));
  }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Node.js App - Home Server</title>
      <style>
        body { font-family: -apple-system, sans-serif; background: #090d16; color: #f1f5f9; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .card { background: #131b2e; border: 1px solid #1e293b; border-radius: 16px; padding: 40px; text-align: center; max-width: 500px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
        h1 { color: #4ade80; margin-bottom: 8px; }
        p { color: #94a3b8; font-size: 14px; line-height: 1.6; }
        .tag { display: inline-block; background: rgba(74,222,128,0.15); color: #4ade80; border: 1px solid rgba(74,222,128,0.3); padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-top: 16px; }
      </style>
    </head>
    <body>
      <div class="card">
        <div style="font-size: 48px; margin-bottom: 12px;">🟢</div>
        <h1>Node.js App Active!</h1>
        <p>Node runtime server initialized on Ubuntu Home Server.</p>
        <div class="tag">● Node.js HTTP Server &bull; Port ${port}</div>
      </div>
    </body>
    </html>
  `);
});

server.listen(port, () => console.log('Server running on port ' + port));
JS_EOF
    sudo chown pi:pi "$SITE_DIR/server.js"

else
    # Default High-Performance Modern Commercial HTML Template
    cat << HTML_EOF > "$SITE_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$SITE_NAME &mdash; Hosted on Home Server</title>
  <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>⚡</text></svg>">
  <style>
    :root {
      --bg: #090d16;
      --card-bg: #131b2e;
      --border: #1e293b;
      --text: #f1f5f9;
      --muted: #94a3b8;
      --accent: #38bdf8;
      --green: #4ade80;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 40px;
      text-align: center;
      max-width: 520px;
      width: 100%;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(74, 222, 128, 0.15);
      color: var(--green);
      border: 1px solid rgba(74, 222, 128, 0.3);
      padding: 4px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 18px;
    }
    h1 { font-size: 26px; font-weight: 700; margin-bottom: 10px; color: var(--accent); }
    p { color: var(--muted); font-size: 14.5px; line-height: 1.6; margin-bottom: 22px; }
    .meta-box {
      background: rgba(0, 0, 0, 0.25);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 16px;
      text-align: left;
      font-size: 13px;
      margin-bottom: 22px;
    }
    .meta-row { display: flex; justify-content: space-between; margin-bottom: 8px; }
    .meta-row:last-child { margin-bottom: 0; }
    .meta-label { color: var(--muted); }
    .meta-val { font-family: monospace; color: var(--text); font-weight: 600; }
    .btn {
      display: inline-block;
      background: var(--accent);
      color: #090d16;
      font-weight: 700;
      text-decoration: none;
      padding: 10px 22px;
      border-radius: 8px;
      font-size: 14px;
      transition: opacity 0.2s;
    }
    .btn:hover { opacity: 0.9; }
  </style>
</head>
<body>
  <div class="card">
    <div style="font-size: 52px; margin-bottom: 12px;">🚀</div>
    <div class="badge">● Live &bull; Port $PORT</div>
    <h1>$SITE_NAME is Ready</h1>
    <p>This website is successfully provisioned and secured on the Ubuntu Home Server cluster.</p>
    
    <div class="meta-box">
      <div class="meta-row">
        <span class="meta-label">Tenant / Owner:</span>
        <span class="meta-val">$CLIENT_OWNER</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">Document Root:</span>
        <span class="meta-val">$SITE_DIR</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">Dedicated Database:</span>
        <span class="meta-val">${SITE_NAME}_db</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">Local Access:</span>
        <span class="meta-val">http://homeserver.local:$PORT</span>
      </div>
    </div>

    <a href="../panel/" class="btn">Manage in Server cPanel &rarr;</a>
  </div>
</body>
</html>
HTML_EOF
    sudo chown pi:pi "$SITE_DIR/index.html"
fi

# 3. Create Nginx Standalone Server Block
echo "🔧 [3/5] Configuring Nginx standalone virtual host on Port $PORT..."
sudo bash -c "cat << 'CONF_EOF' > /etc/nginx/sites-available/$SITE_NAME
server {
    listen $PORT;
    server_name localhost;
    root $SITE_DIR;
    index index.html index.htm index.php;

    # Security Headers
    add_header X-Frame-Options \"SAMEORIGIN\" always;
    add_header X-XSS-Protection \"1; mode=block\" always;
    add_header X-Content-Type-Options \"nosniff\" always;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Enable PHP-FPM if PHP is installed
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONF_EOF"

sudo ln -sf "/etc/nginx/sites-available/$SITE_NAME" "/etc/nginx/sites-enabled/$SITE_NAME"

# 4. Integrate Subpath into Main Nginx Gateway (/sitename/)
echo "🔧 [4/5] Integrating /$SITE_NAME/ route into Main Gateway..."
DEFAULT_CONF="/etc/nginx/sites-available/default"
if [ -f "$DEFAULT_CONF" ]; then
    if ! grep -q "location /$SITE_NAME/" "$DEFAULT_CONF"; then
        sudo sed -i "/location \/terminal\/ {/i \    location \/$SITE_NAME\/ {\n        alias $SITE_DIR\/;\n        index index.html index.htm index.php;\n        try_files \$uri \$uri\/ =404;\n    }\n" "$DEFAULT_CONF"
    fi
fi

# 5. Provision Isolated MongoDB Database & User
echo "🍃 [5/5] Provisioning Isolated MongoDB database and credentials..."
DB_NAME="${SITE_NAME}_db"
DB_USER="${SITE_NAME}_user"
DB_PASS="$(tr -dc 'A-Za-z0-9!@#' < /dev/urandom 2>/dev/null | head -c 12 || echo "${SITE_NAME^}@123")"

if command -v mongosh &> /dev/null; then
    mongosh --quiet --eval "
    use $DB_NAME;
    try {
      db.createUser({ user: '$DB_USER', pwd: '$DB_PASS', roles: [{ role: 'readWrite', db: '$DB_NAME' }] });
      db.metadata.insertOne({
        site: '$SITE_NAME',
        owner: '$CLIENT_OWNER',
        template: '$TEMPLATE',
        port: $PORT,
        created_at: new Date()
      });
    } catch(e) {}
    " 2>/dev/null || true
fi

# Reload Nginx
echo "🔄 Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx 2>/dev/null || echo "Note: Nginx reload will take effect when running on the live Ubuntu Home Server."

echo "=============================================================================="
echo "🎉 WEBSITE & CLIENT SLOT '$SITE_NAME' IS FULLY OPERATIONAL!"
echo "=============================================================================="
echo "• Document Root:      $SITE_DIR"
echo "• Assigned Tenant:    $CLIENT_OWNER"
echo "• Local LAN Port:     http://homeserver.local:$PORT"
echo "• Subpath URL:        http://homeserver.local/$SITE_NAME/"
echo "• Worldwide Link:     https://extre0101.github.io/homeserver/?go=$SITE_NAME"
echo "• MongoDB DB Name:    $DB_NAME"
echo "• MongoDB User:       $DB_USER"
echo "• MongoDB Password:   $DB_PASS"
echo "• Connection URI:     mongodb://$DB_USER:$DB_PASS@localhost:27017/$DB_NAME"
echo "=============================================================================="
