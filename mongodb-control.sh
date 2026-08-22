#!/bin/bash
# ==============================================================================
#  MongoDB Multi-Site Master & Per-Site ON/OFF Control Script
# ==============================================================================

ACTION="${1:-status}"
SITE="${2:-all}"

get_service_name() {
    if systemctl list-unit-files | grep -q "mongod.service"; then
        echo "mongod"
    elif systemctl list-unit-files | grep -q "mongodb.service"; then
        echo "mongodb"
    else
        echo "mongod"
    fi
}

SVC=$(get_service_name)

case "$ACTION" in
    on|start)
        echo "🍃 Starting MongoDB Service ($SVC)..."
        sudo systemctl start "$SVC"
        echo "🟢 MongoDB Service is now RUNNING."
        ;;
    off|stop)
        echo "🛑 Stopping MongoDB Service ($SVC)..."
        sudo systemctl stop "$SVC"
        echo "🔴 MongoDB Service is now STOPPED."
        ;;
    restart)
        echo "🔄 Restarting MongoDB Service ($SVC)..."
        sudo systemctl restart "$SVC"
        echo "🟢 MongoDB Service restarted."
        ;;
    status)
        echo "=============================================================================="
        echo "🍃 MONGODB MASTER & MULTI-SITE STATUS REPORT"
        echo "=============================================================================="
        if systemctl is-active --quiet "$SVC" 2>/dev/null; then
            echo "🟢 Master MongoDB Daemon: ACTIVE (Running on Port 27017)"
        else
            echo "🔴 Master MongoDB Daemon: INACTIVE (Stopped)"
        fi
        echo "------------------------------------------------------------------------------"
        echo "📊 Independent Site Databases:"
        echo "  • site1_db (Website 1): mongodb://site1_user:Site1@123@localhost:27017/site1_db"
        echo "  • site2_db (Website 2): mongodb://site2_user:Site2@123@localhost:27017/site2_db"
        echo "  • site3_db (Website 3): mongodb://site3_user:Site3@123@localhost:27017/site3_db"
        echo "  • site4_db (Website 4): mongodb://site4_user:Site4@123@localhost:27017/site4_db"
        echo "=============================================================================="
        ;;
    test)
        echo "⚡ Testing connection to MongoDB..."
        if command -v mongosh &> /dev/null; then
            mongosh --quiet --eval "db.runCommand({ ping: 1 })"
        elif command -v mongo &> /dev/null; then
            mongo --quiet --eval "db.runCommand({ ping: 1 })"
        else
            echo "⚠️ mongosh / mongo CLI client not found."
        fi
        ;;
    *)
        echo "Usage: $0 {on|off|restart|status|test}"
        exit 1
        ;;
esac
