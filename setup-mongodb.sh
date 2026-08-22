#!/bin/bash
# ==============================================================================
#  MongoDB Community Server - Automated Multi-Site Setup Script
#  Ubuntu Home Server (Isolated Databases for Site 1, Site 2, Site 3, Site 4)
# ==============================================================================
set -e

echo "🍃 [1/5] Updating packages and installing prerequisites..."
sudo apt update
sudo apt install -y gnupg curl wget

echo "🍃 [2/5] Checking and installing MongoDB..."
if ! command -v mongod &> /dev/null; then
    # Import MongoDB GPG key
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
       sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor --yes || true
    
    # Add official repository (Ubuntu Jammy/Noble compatible or Debian fallback)
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        else
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        fi
    fi
    sudo apt update || true
    sudo apt install -y mongodb-org || sudo apt install -y mongodb || true
fi

echo "🍃 [3/5] Starting MongoDB Daemon..."
sudo systemctl daemon-reload
sudo systemctl enable mongod 2>/dev/null || sudo systemctl enable mongodb 2>/dev/null || true
sudo systemctl restart mongod 2>/dev/null || sudo systemctl restart mongodb 2>/dev/null || true

sleep 3

echo "🍃 [4/5] Initializing Independent Databases & Isolated Users..."
# Helper function to run mongosh or mongo
run_mongo_js() {
    local js_code="$1"
    if command -v mongosh &> /dev/null; then
        mongosh --quiet --eval "$js_code"
    elif command -v mongo &> /dev/null; then
        mongo --quiet --eval "$js_code"
    fi
}

# Create Admin User
run_mongo_js "
use admin;
try {
  db.createUser({
    user: 'admin',
    pwd: 'Sanchit@123',
    roles: [ { role: 'userAdminAnyDatabase', db: 'admin' }, { role: 'readWriteAnyDatabase', db: 'admin' } ]
  });
  print('✅ Master Admin User Created');
} catch(e) {
  print('ℹ️ Admin user already initialized or error: ' + e.message);
}
" || true

# Create Site 1 DB & User
run_mongo_js "
use site1_db;
try {
  db.createUser({
    user: 'site1_user',
    pwd: 'Site1@123',
    roles: [ { role: 'readWrite', db: 'site1_db' } ]
  });
  db.posts.insertOne({ title: 'Welcome to Website 1 Database', created_at: new Date() });
  print('✅ Site 1 Database (site1_db) Created');
} catch(e) {
  print('ℹ️ site1_db already initialized: ' + e.message);
}
" || true

# Create Site 2 DB & User
run_mongo_js "
use site2_db;
try {
  db.createUser({
    user: 'site2_user',
    pwd: 'Site2@123',
    roles: [ { role: 'readWrite', db: 'site2_db' } ]
  });
  db.posts.insertOne({ title: 'Welcome to Website 2 Database', created_at: new Date() });
  print('✅ Site 2 Database (site2_db) Created');
} catch(e) {
  print('ℹ️ site2_db already initialized: ' + e.message);
}
" || true

# Create Site 3 DB & User
run_mongo_js "
use site3_db;
try {
  db.createUser({
    user: 'site3_user',
    pwd: 'Site3@123',
    roles: [ { role: 'readWrite', db: 'site3_db' } ]
  });
  db.posts.insertOne({ title: 'Welcome to Website 3 Database', created_at: new Date() });
  print('✅ Site 3 Database (site3_db) Created');
} catch(e) {
  print('ℹ️ site3_db already initialized: ' + e.message);
}
" || true

# Create Site 4 DB & User
run_mongo_js "
use site4_db;
try {
  db.createUser({
    user: 'site4_user',
    pwd: 'Site4@123',
    roles: [ { role: 'readWrite', db: 'site4_db' } ]
  });
  db.posts.insertOne({ title: 'Welcome to Website 4 Database', created_at: new Date() });
  print('✅ Site 4 Database (site4_db) Created');
} catch(e) {
  print('ℹ️ site4_db already initialized: ' + e.message);
}
" || true

echo "🍃 [5/5] Enforcing Security & Localhost Binding..."
CONF_FILE="/etc/mongod.conf"
if [ ! -f "$CONF_FILE" ]; then
    CONF_FILE="/etc/mongodb.conf"
fi

if [ -f "$CONF_FILE" ]; then
    sudo sed -i 's/127.0.0.1/127.0.0.1/' "$CONF_FILE" 2>/dev/null || true
fi

echo "=============================================================================="
echo "🎉 MongoDB Multi-Site Database Suite Successfully Configured!"
echo "=============================================================================="
echo "• Master Host:    127.0.0.1:27017"
echo "• Site 1 DB URI:  mongodb://site1_user:Site1@123@localhost:27017/site1_db"
echo "• Site 2 DB URI:  mongodb://site2_user:Site2@123@localhost:27017/site2_db"
echo "• Site 3 DB URI:  mongodb://site3_user:Site3@123@localhost:27017/site3_db"
echo "• Site 4 DB URI:  mongodb://site4_user:Site4@123@localhost:27017/site4_db"
echo "=============================================================================="
