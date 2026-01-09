#!/bin/bash

# Eero Dashboard Update Script for Raspberry Pi
# Updates dashboard with latest features including SSL and network binding

set -e

echo "🔄 Updating Eero Dashboard on Raspberry Pi"
echo "=========================================="

# Check if running as correct user
if [ "$USER" != "wifi" ]; then
    echo "⚠️  This script should be run as the 'wifi' user"
    echo "💡 Switch to wifi user: sudo su - wifi"
    exit 1
fi

# Configuration
DASHBOARD_DIR="/home/wifi/eero-dashboard"
BACKUP_DIR="/home/wifi/eero-dashboard/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "📋 Creating backup of current dashboard..."
cp "$DASHBOARD_DIR/dashboard.py" "$BACKUP_DIR/dashboard.py.backup.$TIMESTAMP"

echo "📥 Downloading latest dashboard updates..."

# Download updated dashboard.py
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/dashboard.py -o "$DASHBOARD_DIR/dashboard.py.new"

# Verify download was successful
if [ ! -f "$DASHBOARD_DIR/dashboard.py.new" ] || [ ! -s "$DASHBOARD_DIR/dashboard.py.new" ]; then
    echo "❌ Failed to download updated dashboard"
    exit 1
fi

# Replace the dashboard file
mv "$DASHBOARD_DIR/dashboard.py.new" "$DASHBOARD_DIR/dashboard.py"

echo "📥 Downloading SSL setup script..."
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/setup-ssl.sh -o "$DASHBOARD_DIR/setup-ssl.sh"
chmod +x "$DASHBOARD_DIR/setup-ssl.sh"

echo "📥 Downloading network binding configuration script..."
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/configure-network-binding.sh -o "$DASHBOARD_DIR/configure-network-binding.sh"
chmod +x "$DASHBOARD_DIR/configure-network-binding.sh"

echo "📥 Downloading voice endpoint test script..."
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/test-voice-endpoints.sh -o "$DASHBOARD_DIR/test-voice-endpoints.sh"
chmod +x "$DASHBOARD_DIR/test-voice-endpoints.sh"

echo "✅ Dashboard files updated successfully"

# Check if voice endpoints exist, if not add them
if ! grep -q "/api/voice/status" "$DASHBOARD_DIR/dashboard.py"; then
    echo "🎤 Adding voice endpoints for Echo integration..."
    curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/add-voice-endpoints.sh | bash
else
    echo "✅ Voice endpoints already present"
fi

echo "🔄 Restarting dashboard service..."
sudo systemctl restart eero-dashboard

# Wait for service to start
sleep 5

# Check service status
if sudo systemctl is-active --quiet eero-dashboard; then
    echo "✅ Dashboard service restarted successfully"
    
    # Get Pi IP address
    PI_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "🎉 Dashboard update completed successfully!"
    echo ""
    echo "📋 New Features Available:"
    echo "   🔒 SSL/HTTPS Support"
    echo "   🌐 Network Interface Binding"
    echo "   🎤 Voice API Endpoints"
    echo "   ⚙️  Enhanced Admin Panel"
    echo ""
    echo "🌐 Access dashboard at:"
    echo "   HTTP:  http://$PI_IP"
    echo "   Admin: http://$PI_IP (click admin panel)"
    echo ""
    echo "🔧 Available Configuration Scripts:"
    echo "   SSL Setup:           $DASHBOARD_DIR/setup-ssl.sh"
    echo "   Network Binding:     $DASHBOARD_DIR/configure-network-binding.sh"
    echo "   Test Voice Endpoints: $DASHBOARD_DIR/test-voice-endpoints.sh"
    echo ""
    echo "🎤 Voice API Endpoints:"
    echo "   http://$PI_IP/api/voice/status"
    echo "   http://$PI_IP/api/voice/devices"
    echo "   http://$PI_IP/api/voice/aps"
    echo "   http://$PI_IP/api/voice/events"
    echo ""
    echo "📋 Next Steps:"
    echo "1. 🔒 Setup SSL: ./setup-ssl.sh"
    echo "2. 🌐 Configure network binding: ./configure-network-binding.sh"
    echo "3. 🧪 Test voice endpoints: ./test-voice-endpoints.sh"
    echo "4. 🎤 Update your Echo skill Lambda with new Pi IP/protocol"
    
else
    echo "❌ Dashboard service failed to start"
    echo "🔍 Check logs: sudo journalctl -u eero-dashboard -f"
    echo "🔄 Try manual restart: sudo systemctl restart eero-dashboard"
    
    # Show recent logs
    echo ""
    echo "📋 Recent logs:"
    sudo journalctl -u eero-dashboard --no-pager -l --lines=10
fi

echo ""
echo "📁 Backup created at: $BACKUP_DIR/dashboard.py.backup.$TIMESTAMP"
echo "✅ Update complete!"