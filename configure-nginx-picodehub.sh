#!/bin/bash
# ==============================================================================
#  Route PiCodeHub to Website 1 (/site1/ & Port 8001) in Nginx
# ==============================================================================
set -e

echo "🔧 [1/3] Configuring Nginx Reverse Proxy for Site 1 (Port 8001)..."
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

# Enable site1 if not already linked
sudo ln -sf /etc/nginx/sites-available/site1 /etc/nginx/sites-enabled/site1

echo "🔧 [2/3] Updating Main Hub Nginx Configuration (/site1/ path)..."
# Add or update /site1/ proxy location in default site if exists
if [ -f /etc/nginx/sites-available/default ]; then
    # Backup default config
    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
    
    # Check if proxy_pass for /site1/ already exists
    if grep -q "location /site1/" /etc/nginx/sites-available/default; then
        echo "ℹ️ Location /site1/ already exists in default config. Updating..."
        sudo sed -i '/location \/site1\/ {/,/}/c\    location /site1/ {\n        proxy_pass http://127.0.0.1:5000/;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto $scheme;\n    }' /etc/nginx/sites-available/default
    fi
fi

echo "🔧 [3/3] Testing and Reloading Nginx..."
sudo nginx -t
sudo systemctl reload nginx

echo "=============================================================================="
echo "🎉 PiCodeHub successfully routed to Website 1!"
echo "• Local LAN Access:        http://homeserver.local/site1/ (or :8001)"
echo "• Worldwide Cloudflare:    https://extre0101.github.io/homeserver/?go=site1"
echo "=============================================================================="
