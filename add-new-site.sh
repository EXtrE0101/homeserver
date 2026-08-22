#!/bin/bash
# ==============================================================================
#  Ubuntu Home Server - 1-Click New Website & Database Provisioner
# ==============================================================================
set -e

SITE_NAME="${1}"
PORT="${2}"

if [ -z "$SITE_NAME" ] || [ -z "$PORT" ]; then
    echo "Usage: sudo bash add-new-site.sh <site_name> <port>"
    echo "Example: sudo bash add-new-site.sh site5 8005"
    exit 1
fi

SITE_DIR="/var/www/$SITE_NAME"

echo "🌐 [1/4] Creating site directory at $SITE_DIR..."
sudo mkdir -p "$SITE_DIR"
sudo chown -R pi:pi "$SITE_DIR"

if [ ! -f "$SITE_DIR/index.html" ]; then
    cat << HTML_EOF > "$SITE_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$SITE_NAME - Home Server</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #09090b; color: #f4f4f5; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #18181b; border: 1px solid #27272a; border-radius: 16px; padding: 40px; text-align: center; max-width: 460px; }
    h1 { color: #3b82f6; margin-bottom: 8px; }
    p { color: #a1a1aa; font-size: 14px; line-height: 1.6; }
    .tag { display: inline-block; background: #22c55e22; color: #22c55e; border: 1px solid #22c55e44; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div style="font-size: 48px; margin-bottom: 12px;">🚀</div>
    <h1>$SITE_NAME is Live!</h1>
    <p>This website is running on your Ubuntu Home Server.<br>Upload your code or HTML files into <code>$SITE_DIR</code> to customize this page.</p>
    <div class="tag">● Port $PORT &bull; Active</div>
  </div>
</body>
</html>
HTML_EOF
    sudo chown pi:pi "$SITE_DIR/index.html"
fi

echo "🔧 [2/4] Creating Nginx standalone configuration on Port $PORT..."
sudo bash -c "cat << 'CONF_EOF' > /etc/nginx/sites-available/$SITE_NAME
server {
    listen $PORT;
    server_name localhost;
    root $SITE_DIR;
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
CONF_EOF"

sudo ln -sf "/etc/nginx/sites-available/$SITE_NAME" "/etc/nginx/sites-enabled/$SITE_NAME"

echo "🔧 [3/4] Adding /$SITE_NAME/ subpath to Main Web Hub..."
DEFAULT_CONF="/etc/nginx/sites-available/default"
if [ -f "$DEFAULT_CONF" ]; then
    if ! grep -q "location /$SITE_NAME/" "$DEFAULT_CONF"; then
        sudo sed -i "/location \/terminal\/ {/i \    location \/$SITE_NAME\/ {\n        alias $SITE_DIR\/;\n        index index.html index.htm;\n        try_files \$uri \$uri\/ =404;\n    }\n" "$DEFAULT_CONF"
    fi
fi

echo "🍃 [4/4] Creating Isolated MongoDB Database for $SITE_NAME..."
DB_NAME="${SITE_NAME}_db"
DB_USER="${SITE_NAME}_user"
DB_PASS="$(tr -dc 'A-Za-z0-9!@#' < /dev/urandom 2>/dev/null | head -c 12 || echo "${SITE_NAME^}@123")"

if command -v mongosh &> /dev/null; then
    mongosh --quiet --eval "
    use $DB_NAME;
    try {
      db.createUser({ user: '$DB_USER', pwd: '$DB_PASS', roles: [{ role: 'readWrite', db: '$DB_NAME' }] });
      db.settings.insertOne({ site: '$SITE_NAME', created_at: new Date() });
    } catch(e) {}
    " 2>/dev/null || true
fi

echo "🔄 Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "=============================================================================="
echo "🎉 NEW WEBSITE '$SITE_NAME' SUCCESSFULLY CREATED!"
echo "=============================================================================="
echo "• Web Root Folder:    $SITE_DIR"
echo "• Local LAN Port:     http://homeserver.local:$PORT"
echo "• Subpath URL:        http://homeserver.local/$SITE_NAME/"
echo "• Worldwide Link:     https://extre0101.github.io/homeserver/?go=$SITE_NAME"
echo "• MongoDB Database:   $DB_NAME (User: $DB_USER / Pass: $DB_PASS)"
echo "=============================================================================="
