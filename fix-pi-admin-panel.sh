#!/bin/bash

# Fix Pi Admin Panel - Download and Apply Clean Layout
# Run this on your Raspberry Pi to fix the admin panel formatting

set -e

echo "🎨 Fixing Pi Admin Panel Layout..."

# Check if we're in the dashboard directory
if [[ ! -f "dashboard.py" ]]; then
    echo "❌ Please run this script from the eero-dashboard directory"
    echo "   cd ~/eero-dashboard"
    echo "   ./fix-pi-admin-panel.sh"
    exit 1
fi

# Stop dashboard service temporarily
echo "🛑 Stopping dashboard service..."
sudo systemctl stop eero-dashboard.service

# Create backup
echo "📋 Creating backup..."
cp index.html index.html.backup.$(date +%Y%m%d_%H%M%S)

# Download the admin panel fix script
echo "📥 Downloading admin panel fix..."
wget -O fix-admin-panel-layout.sh https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/fix-admin-panel-layout.sh
chmod +x fix-admin-panel-layout.sh

# Apply the fix
echo "🔧 Applying admin panel improvements..."
./fix-admin-panel-layout.sh

# Restart dashboard service
echo "🔄 Restarting dashboard service..."
sudo systemctl start eero-dashboard.service

# Wait for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet eero-dashboard.service; then
    echo "✅ Dashboard service restarted successfully"
else
    echo "❌ Dashboard service failed to start, restoring backup..."
    cp index.html.backup.* index.html
    sudo systemctl start eero-dashboard.service
    exit 1
fi

# Get IP address for access
WLAN_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)
ETH_IP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)

echo ""
echo "🎉 Admin Panel Fixed Successfully!"
echo "================================="
echo ""
echo "📋 Improvements Applied:"
echo "   ✅ Clean, organized layout with sections"
echo "   ✅ Interface Access Controls button added"
echo "   ✅ Boot Notification Settings button added"
echo "   ✅ Professional visual design"
echo "   ✅ Mobile-friendly responsive layout"
echo ""
echo "🌐 Access Your Dashboard:"
if [[ -n "$WLAN_IP" ]]; then
    echo "   WiFi:     https://$WLAN_IP"
fi
if [[ -n "$ETH_IP" ]]; then
    echo "   Ethernet: https://$ETH_IP"
fi
echo ""
echo "🔧 Click the π (pi) icon to see the improved admin panel!"
echo ""
echo "📋 New Admin Panel Sections:"
echo "   • System Management - Updates, Interface Controls, Boot Notifications"
echo "   • Network Configuration - Networks, Authentication"  
echo "   • Display & Interface - Kiosk Mode, Timezone"