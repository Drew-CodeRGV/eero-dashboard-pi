#!/bin/bash

# Update Dashboard with Interface Controls and Boot Notification
# This script updates the Pi dashboard with the new admin panel features

set -e

echo "🚀 Updating Eero Dashboard with Interface Controls and Boot Notification..."

# Check if running as the correct user
if [[ $EUID -eq 0 ]]; then
    echo "❌ Please run this script as the wifi user, not as root"
    echo "   The script will use sudo when needed"
    exit 1
fi

# Ensure we're in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 Working directory: $SCRIPT_DIR"

# Stop the dashboard service
echo "🛑 Stopping dashboard service..."
sudo systemctl stop eero-dashboard.service || true

# Create backup of current files
echo "📋 Creating backup of current files..."
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup important files
if [[ -f "dashboard.py" ]]; then
    cp dashboard.py "$BACKUP_DIR/"
fi
if [[ -f "index.html" ]]; then
    cp index.html "$BACKUP_DIR/"
fi

echo "✅ Backup created in: $BACKUP_DIR"

# Update dashboard.py (already has the new features)
echo "✅ dashboard.py already contains interface controls and boot notification"

# Add admin panel UI components
echo "🔧 Adding admin panel UI components..."
if [[ -f "add-admin-interface-controls.sh" ]]; then
    ./add-admin-interface-controls.sh
else
    echo "⚠️  Admin interface controls script not found, skipping UI updates"
fi

# Setup boot notification service
echo "🔧 Setting up boot notification service..."
if [[ -f "setup-boot-notification.sh" ]]; then
    ./setup-boot-notification.sh
else
    echo "⚠️  Boot notification setup script not found, skipping service setup"
fi

# Restart the dashboard service
echo "🔄 Restarting dashboard service..."
sudo systemctl start eero-dashboard.service

# Wait a moment for service to start
sleep 3

# Check service status
echo "📊 Checking service status..."
if sudo systemctl is-active --quiet eero-dashboard.service; then
    echo "✅ Dashboard service is running"
else
    echo "❌ Dashboard service failed to start"
    echo "📋 Service status:"
    sudo systemctl status eero-dashboard.service --no-pager || true
    echo ""
    echo "📋 Recent logs:"
    sudo journalctl -u eero-dashboard.service -n 20 --no-pager || true
    exit 1
fi

# Get the current IP address for access
WLAN_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)
ETH_IP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)

echo ""
echo "🎉 Dashboard update completed successfully!"
echo ""
echo "📋 New Features Added:"
echo "   ✅ Interface Access Controls"
echo "      - Control wired/wireless interface access"
echo "      - Both interfaces enabled by default"
echo "   ✅ Boot Notification System"
echo "      - Email notifications on system startup"
echo "      - Includes IP addresses of all interfaces"
echo "      - Configurable SMTP settings"
echo ""
echo "🌐 Dashboard Access:"
if [[ -n "$WLAN_IP" ]]; then
    echo "   WiFi:     https://$WLAN_IP"
fi
if [[ -n "$ETH_IP" ]]; then
    echo "   Ethernet: https://$ETH_IP"
fi
echo ""
echo "🔧 Configuration:"
echo "   1. Open the dashboard in your browser"
echo "   2. Click the π (pi) icon to open Admin Panel"
echo "   3. Configure 'Interface Access Controls' as needed"
echo "   4. Configure 'Boot Notification Settings' with your email"
echo "   5. Use 'Send Test Email' to verify email settings"
echo ""
echo "📋 Service Management:"
echo "   Status:           sudo systemctl status eero-dashboard.service"
echo "   Logs:             sudo journalctl -u eero-dashboard.service -f"
echo "   Boot notification: sudo systemctl status boot-notification.service"
echo "   Boot logs:        sudo journalctl -u boot-notification.service -f"
echo ""
echo "⚠️  Note: Boot notifications will be sent automatically on next system restart"
echo "   To test immediately: sudo systemctl start boot-notification.service"