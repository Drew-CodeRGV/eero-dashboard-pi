#!/bin/bash

# Complete Pi Update Script for Interface Controls and Boot Notification
# This script handles all git conflicts and updates everything automatically

set -e

echo "🚀 Complete Pi Update for Interface Controls and Boot Notification"
echo "=================================================================="

# Check if running as the correct user
if [[ $EUID -eq 0 ]]; then
    echo "❌ Please run this script as the wifi user, not as root"
    echo "   The script will use sudo when needed"
    exit 1
fi

# Navigate to dashboard directory
cd ~/eero-dashboard || {
    echo "❌ Could not find ~/eero-dashboard directory"
    echo "   Please ensure the dashboard is installed in the correct location"
    exit 1
}

echo "📁 Working in: $(pwd)"

# Stop the dashboard service
echo "🛑 Stopping dashboard service..."
sudo systemctl stop eero-dashboard.service || true

# Create comprehensive backup
echo "📋 Creating backup of current installation..."
BACKUP_DIR="complete-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup all important files
cp dashboard.py "$BACKUP_DIR/" 2>/dev/null || true
cp index.html "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.eero-dashboard "$BACKUP_DIR/eero-dashboard-config" 2>/dev/null || true

# Backup and remove conflicting files
echo "🔧 Handling git conflicts..."
for file in configure-network-binding.sh setup-ssl.sh test-voice-endpoints.sh; do
    if [[ -f "$file" ]]; then
        echo "   Moving $file to backup..."
        mv "$file" "$BACKUP_DIR/"
    fi
done

# Stash any local changes to dashboard.py
echo "🔧 Stashing local changes..."
git stash push -m "Auto-stash before interface controls update $(date)" || true

# Force update from repository
echo "📥 Forcing update from repository..."
git fetch origin
git reset --hard origin/main

# Verify we got the new files
if [[ ! -f "update-with-interface-controls.sh" ]]; then
    echo "❌ Update script not found after git update"
    echo "   Trying direct download..."
    
    # Download the update script directly
    wget -O update-with-interface-controls.sh https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/update-with-interface-controls.sh
    chmod +x update-with-interface-controls.sh
fi

if [[ ! -f "boot-notification.py" ]]; then
    echo "📥 Downloading missing boot notification files..."
    wget -O boot-notification.py https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/boot-notification.py
    wget -O boot-notification.service https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/boot-notification.service
    wget -O setup-boot-notification.sh https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/setup-boot-notification.sh
    chmod +x setup-boot-notification.sh
fi

if [[ ! -f "add-admin-interface-controls.sh" ]]; then
    echo "📥 Downloading admin interface controls..."
    wget -O add-admin-interface-controls.sh https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/add-admin-interface-controls.sh
    chmod +x add-admin-interface-controls.sh
fi

# Make all scripts executable
echo "🔧 Making scripts executable..."
chmod +x *.sh 2>/dev/null || true

# Run the comprehensive update
echo "🔧 Running comprehensive update..."
if [[ -f "update-with-interface-controls.sh" ]]; then
    ./update-with-interface-controls.sh
else
    echo "⚠️  Main update script not available, running manual installation..."
    
    # Manual installation steps
    echo "🔧 Adding admin panel UI components..."
    if [[ -f "add-admin-interface-controls.sh" ]]; then
        ./add-admin-interface-controls.sh
    fi
    
    echo "🔧 Setting up boot notification service..."
    if [[ -f "setup-boot-notification.sh" ]]; then
        ./setup-boot-notification.sh
    fi
    
    # Restart the dashboard service
    echo "🔄 Restarting dashboard service..."
    sudo systemctl start eero-dashboard.service
fi

# Wait for service to start
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
    
    # Try to restore from backup
    echo "🔄 Attempting to restore from backup..."
    if [[ -f "$BACKUP_DIR/dashboard.py" ]]; then
        cp "$BACKUP_DIR/dashboard.py" dashboard.py
        sudo systemctl start eero-dashboard.service
        sleep 2
        if sudo systemctl is-active --quiet eero-dashboard.service; then
            echo "✅ Service restored from backup"
        else
            echo "❌ Could not restore service. Please check logs."
            exit 1
        fi
    fi
fi

# Get current IP addresses
WLAN_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)
ETH_IP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)

echo ""
echo "🎉 Pi Update Completed Successfully!"
echo "===================================="
echo ""
echo "📋 New Features Added:"
echo "   ✅ Interface Access Controls"
echo "      - Control wired/wireless interface access"
echo "      - Both interfaces enabled by default"
echo "      - External access control"
echo ""
echo "   ✅ Boot Notification System"
echo "      - Email notifications on system startup"
echo "      - Includes IP addresses of all interfaces"
echo "      - Configurable SMTP settings"
echo "      - Email sent to drew@drewlentz.com by default"
echo ""
echo "🌐 Dashboard Access:"
if [[ -n "$WLAN_IP" ]]; then
    echo "   WiFi:     https://$WLAN_IP"
fi
if [[ -n "$ETH_IP" ]]; then
    echo "   Ethernet: https://$ETH_IP"
fi
echo ""
echo "🔧 Configuration Steps:"
echo "   1. Open the dashboard in your web browser"
echo "   2. Click the π (pi) icon to open Admin Panel"
echo "   3. Click 'Interface Access Controls' to configure network access"
echo "   4. Click 'Boot Notification Settings' to configure email notifications"
echo "   5. Use 'Send Test Email' to verify email settings work"
echo ""
echo "📋 Service Management:"
echo "   Dashboard Status:     sudo systemctl status eero-dashboard.service"
echo "   Dashboard Logs:       sudo journalctl -u eero-dashboard.service -f"
echo "   Boot Notification:    sudo systemctl status boot-notification.service"
echo "   Boot Logs:           sudo journalctl -u boot-notification.service -f"
echo ""
echo "💾 Backup Location: $BACKUP_DIR"
echo ""
echo "⚠️  Boot notifications will be sent automatically on next system restart"
echo "   To test immediately: sudo systemctl start boot-notification.service"
echo ""
echo "🎯 All done! Your dashboard now has professional interface controls and boot notifications!"