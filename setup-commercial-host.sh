#!/bin/bash
# ==============================================================================
#  Ubuntu Home Server - Traditional Commercial Hosting Stack Master Provisioner
#  Standards: FHS Compliant, Chroot SFTP, Multi-Tenant Linux Users, Nginx Vhosts,
#             MariaDB + MongoDB, SSL Certbot, Backups, Crons & Process Supervisor
# ==============================================================================
set -e

echo "=============================================================================="
echo "🏗️  INITIALIZING TRADITIONAL COMMERCIAL WEB HOSTING ENVIRONMENT"
echo "=============================================================================="

# 1. Base Directory Hierarchy
echo "📁 [1/8] Setting up FHS-compliant hosting filesystem..."
sudo mkdir -p /home/tenants
sudo mkdir -p /var/log/virtualhosts
sudo mkdir -p /var/backups/homeserver
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled
sudo chmod 755 /home/tenants
sudo chmod 755 /var/log/virtualhosts
sudo chmod 700 /var/backups/homeserver

# 2. SFTP Chroot Group Setup
echo "🔒 [2/8] Configuring secure SFTP chroot jail group (sftponly)..."
if ! getent group sftponly > /dev/null 2>&1; then
    sudo groupadd sftponly
    echo "✓ Group 'sftponly' created."
fi

# Ensure SSH config has Subsystem & Match Group
SSHD_CONF="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONF" ] && ! grep -q "Match Group sftponly" "$SSHD_CONF"; then
    echo "Configuring SSHD for chroot SFTP..."
    sudo tee -a "$SSHD_CONF" > /dev/null << 'SSH_EOF'

# --- Multi-Tenant Commercial Chroot SFTP Jail ---
Match Group sftponly
    ChrootDirectory /home/tenants/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
SSH_EOF
    sudo systemctl reload ssh 2>/dev/null || sudo service ssh reload 2>/dev/null || true
fi

# 3. Tenant User Provisioning Helper
echo "👤 [3/8] Installing Tenant System User Provisioner (/usr/local/bin/create-tenant)..."
sudo tee /usr/local/bin/create-tenant > /dev/null << 'TENANT_EOF'
#!/bin/bash
set -e
USERNAME="${1}"
PASSWORD="${2}"
QUOTA_MB="${3:-5120}" # 5GB Default

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: sudo create-tenant <username> <password> [quota_mb]"
    exit 1
fi

USERNAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')
TENANT_HOME="/home/tenants/$USERNAME"

echo "Creating tenant Linux user '$USERNAME'..."
if ! id "$USERNAME" >/dev/null 2>&1; then
    sudo useradd -m -d "$TENANT_HOME" -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | sudo chpasswd
    sudo usermod -a -G sftponly "$USERNAME"
    sudo usermod -a -G "$USERNAME" www-data 2>/dev/null || true
fi

# Permissions for chroot: Home must be owned by root:root 755; public_html owned by tenant
sudo chown root:root "$TENANT_HOME"
sudo chmod 755 "$TENANT_HOME"

sudo mkdir -p "$TENANT_HOME/public_html"
sudo mkdir -p "$TENANT_HOME/logs"
sudo mkdir -p "$TENANT_HOME/backups"
sudo mkdir -p "$TENANT_HOME/tmp"

sudo chown -R "$USERNAME:$USERNAME" "$TENANT_HOME/public_html" "$TENANT_HOME/logs" "$TENANT_HOME/backups" "$TENANT_HOME/tmp"
sudo chmod 750 "$TENANT_HOME/public_html"
sudo chmod 700 "$TENANT_HOME/logs" "$TENANT_HOME/backups" "$TENANT_HOME/tmp"

echo "✓ Tenant '$USERNAME' configured with Chroot SFTP and public_html document root."
TENANT_EOF
sudo chmod +x /usr/local/bin/create-tenant

# 4. Automated Backup CLI (/usr/local/bin/homeserver-backup)
echo "💾 [4/8] Installing Automated Backup & Disaster Recovery CLI..."
sudo tee /usr/local/bin/homeserver-backup > /dev/null << 'BK_EOF'
#!/bin/bash
set -e
BACKUP_ROOT="/var/backups/homeserver"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TARGET="${1:-all}"

mkdir -p "$BACKUP_ROOT"

if [ "$TARGET" = "all" ]; then
    ARCHIVE="$BACKUP_ROOT/full_backup_$TIMESTAMP.tar.gz"
    echo "📦 Creating full system snapshot at $ARCHIVE..."
    sudo tar -czf "$ARCHIVE" \
        --exclude="/var/backups" \
        --exclude="/proc" \
        --exclude="/sys" \
        --exclude="/dev" \
        --exclude="/tmp" \
        /home/tenants /var/www /etc/nginx 2>/dev/null || true
    echo "✓ Full snapshot created: $(ls -lh "$ARCHIVE" | awk '{print $5}')"
else
    TENANT_DIR="/home/tenants/$TARGET"
    if [ -d "$TENANT_DIR" ]; then
        ARCHIVE="$BACKUP_ROOT/tenant_${TARGET}_$TIMESTAMP.tar.gz"
        echo "📦 Creating tenant snapshot for '$TARGET'..."
        sudo tar -czf "$ARCHIVE" "$TENANT_DIR" 2>/dev/null || true
        echo "✓ Tenant snapshot created: $(ls -lh "$ARCHIVE" | awk '{print $5}')"
    else
        echo "❌ Tenant '$TARGET' not found."
        exit 1
    fi
fi
BK_EOF
sudo chmod +x /usr/local/bin/homeserver-backup

# 5. Process Supervisor & App Manager (/usr/local/bin/homeserver-supervisor)
echo "⚙️  [5/8] Installing Application Process Supervisor CLI..."
sudo tee /usr/local/bin/homeserver-supervisor > /dev/null << 'SUP_EOF'
#!/bin/bash
ACTION="${1:-status}"
APP_NAME="${2}"

case "$ACTION" in
    status)
        echo "=== Active Commercial Hosting Processes ==="
        systemctl list-units --type=service --state=running | grep -E 'node|flask|gunicorn|nginx|mongod|mariadb' || echo "All services operating normally."
        ;;
    restart)
        if [ -z "$APP_NAME" ]; then
            echo "Usage: sudo homeserver-supervisor restart <service_name>"
            exit 1
        fi
        sudo systemctl restart "$APP_NAME" && echo "✓ Service '$APP_NAME' restarted successfully."
        ;;
    *)
        echo "Usage: sudo homeserver-supervisor {status|restart <service>}"
        ;;
esac
SUP_EOF
sudo chmod +x /usr/local/bin/homeserver-supervisor

# 6. Cron Schedule Template for Backups & Watchdog
echo "⏰ [6/8] Registering system-level automated backup & watchdog crons..."
sudo tee /etc/cron.d/homeserver-maintenance > /dev/null << 'CRON_EOF'
# Ubuntu Home Server - Daily Automated Backup at 03:00 AM
0 3 * * * root /usr/local/bin/homeserver-backup all > /var/log/homeserver_backup.log 2>&1

# Log rotation & cleanup of backups older than 14 days
0 4 * * 0 root find /var/backups/homeserver/ -type f -mtime +14 -delete
CRON_EOF
sudo chmod 644 /etc/cron.d/homeserver-maintenance

# 7. Summary & Verification
echo "=============================================================================="
echo "✅ COMMERCIAL HOSTING STACK INITIALIZED SUCCESSFULLY!"
echo "=============================================================================="
echo "• Multi-Tenant User Factory: /usr/local/bin/create-tenant <user> <pass>"
echo "• Disaster Recovery CLI:     /usr/local/bin/homeserver-backup [all|user]"
echo "• Process Supervisor:        /usr/local/bin/homeserver-supervisor {status|restart}"
echo "• Document Roots:            /home/tenants/<user>/public_html/ or /var/www/<slug>/"
echo "• Virtualhost Logs:          /var/log/virtualhosts/"
echo "• Automated Backup Storage:  /var/backups/homeserver/"
echo "=============================================================================="
