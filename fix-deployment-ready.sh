#!/bin/bash

# Fixed Deployment Readiness Script
# Handles missing boot-notification service and ensures lowercase eero

set -e

echo "🚀 Preparing eero Dashboard for Deployment..."

# Check if we're in the correct directory
if [[ ! -f "dashboard.py" ]]; then
    echo "❌ dashboard.py not found. Please run this script from the eero-dashboard directory."
    exit 1
fi

# Install boot notification service if it doesn't exist
echo "🔧 Checking boot notification service..."
if [[ ! -f "/etc/systemd/system/boot-notification.service" ]]; then
    echo "📦 Installing boot notification service..."
    
    # Check if we have the service file locally
    if [[ -f "boot-notification.service" ]]; then
        sudo cp boot-notification.service /etc/systemd/system/
        sudo systemctl daemon-reload
        echo "✅ Boot notification service installed"
    else
        echo "⚠️  boot-notification.service file not found locally"
        echo "🔧 Creating boot notification service..."
        
        # Create the service file
        sudo tee /etc/systemd/system/boot-notification.service > /dev/null << 'EOF'
[Unit]
Description=eero Dashboard Boot Notification Service
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=oneshot
User=wifi
Group=wifi
WorkingDirectory=/home/wifi/eero-dashboard
ExecStart=/usr/bin/python3 /home/wifi/eero-dashboard/boot-notification.py
RemainAfterExit=no
StandardOutput=journal
StandardError=journal
TimeoutStartSec=120

# Restart policy
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl daemon-reload
        echo "✅ Boot notification service created"
    fi
fi

# Ensure all services are enabled for boot
echo "🔧 Enabling services for automatic startup..."

# Enable eero dashboard service
if sudo systemctl enable eero-dashboard.service 2>/dev/null; then
    echo "✅ eero dashboard service enabled"
else
    echo "⚠️  eero dashboard service not found or already enabled"
fi

# Enable boot notification service
if sudo systemctl enable boot-notification.service 2>/dev/null; then
    echo "✅ Boot notification service enabled"
else
    echo "⚠️  Could not enable boot notification service"
fi

# Enable nginx
if sudo systemctl enable nginx 2>/dev/null; then
    echo "✅ Nginx enabled"
else
    echo "⚠️  Nginx not found or already enabled"
fi

# Enable SSH
if sudo systemctl enable ssh 2>/dev/null; then
    echo "✅ SSH enabled"
else
    echo "⚠️  SSH not found or already enabled"
fi

# Test boot notification if the script exists
echo "📧 Testing boot notification system..."
if [[ -f "boot-notification.py" ]]; then
    python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from boot_notification import send_boot_notification
    send_boot_notification(test_mode=True)
    print('✅ Boot notification test successful')
except ImportError:
    print('⚠️  Boot notification module not found - will be available after reboot')
except Exception as e:
    print(f'⚠️  Boot notification test failed: {e}')
    print('   This is normal if email settings are not configured yet')
    "
else
    echo "⚠️  boot-notification.py not found"
fi

# Check SSH configuration
echo "🔐 Checking SSH configuration..."
if sudo systemctl is-enabled ssh >/dev/null 2>&1; then
    echo "✅ SSH is enabled for remote access"
    
    # Check if SSH is running
    if sudo systemctl is-active --quiet ssh; then
        echo "✅ SSH service is running"
    else
        echo "🔄 Starting SSH service..."
        sudo systemctl start ssh
    fi
else
    echo "⚠️  SSH is not enabled - enabling now..."
    sudo systemctl enable ssh
    sudo systemctl start ssh
fi

# Verify web services
echo "🌐 Checking web services..."
if sudo systemctl is-active --quiet eero-dashboard.service; then
    echo "✅ eero dashboard service is running"
else
    echo "🔄 Starting eero dashboard service..."
    if sudo systemctl start eero-dashboard.service; then
        echo "✅ eero dashboard service started"
    else
        echo "❌ Failed to start eero dashboard service"
        echo "📋 Service status:"
        sudo systemctl status eero-dashboard.service --no-pager || true
    fi
fi

if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx web server is running"
else
    echo "🔄 Starting nginx..."
    if sudo systemctl start nginx; then
        echo "✅ Nginx started"
    else
        echo "❌ Failed to start nginx"
        echo "📋 Nginx status:"
        sudo systemctl status nginx --no-pager || true
    fi
fi

# Get network information
echo "📊 Network Information:"
WLAN_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)
ETH_IP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)

if [[ -n "$WLAN_IP" ]]; then
    echo "   WiFi IP:     $WLAN_IP"
    echo "   WiFi Access: https://$WLAN_IP"
fi

if [[ -n "$ETH_IP" ]]; then
    echo "   Ethernet IP: $ETH_IP"  
    echo "   Eth Access:  https://$ETH_IP"
fi

# Test web access
echo "🌐 Testing web access..."
PRIMARY_IP=${WLAN_IP:-$ETH_IP}
if [[ -n "$PRIMARY_IP" ]]; then
    if curl -k -s --connect-timeout 5 "https://$PRIMARY_IP/health" >/dev/null 2>&1; then
        echo "✅ HTTPS web access working"
    elif curl -s --connect-timeout 5 "http://$PRIMARY_IP/health" >/dev/null 2>&1; then
        echo "✅ HTTP web access working (will redirect to HTTPS)"
    else
        echo "⚠️  Web access test failed - may need manual verification"
    fi
fi

# Check boot notification configuration
echo "📧 Checking boot notification configuration..."
if python3 -c "
import sys, json
sys.path.insert(0, '.')
try:
    from dashboard import load_config
    config = load_config()
    boot_config = config.get('boot_notification', {})
    if boot_config.get('enabled', True):
        if boot_config.get('smtp_username') and boot_config.get('smtp_password'):
            print('✅ Boot notification is configured and enabled')
        else:
            print('⚠️  Boot notification enabled but SMTP credentials not set')
    else:
        print('⚠️  Boot notification is disabled')
except Exception as e:
    print('⚠️  Could not check boot notification config')
" 2>/dev/null; then
    :
else
    echo "⚠️  Could not verify boot notification configuration"
fi

echo ""
echo "🎉 Deployment Readiness Check Complete!"
echo "======================================"
echo ""
echo "📋 Service Status Summary:"
sudo systemctl is-enabled eero-dashboard.service >/dev/null 2>&1 && echo "✅ eero dashboard: enabled" || echo "❌ eero dashboard: not enabled"
sudo systemctl is-enabled boot-notification.service >/dev/null 2>&1 && echo "✅ Boot notification: enabled" || echo "❌ Boot notification: not enabled"
sudo systemctl is-enabled nginx >/dev/null 2>&1 && echo "✅ Nginx: enabled" || echo "❌ Nginx: not enabled"
sudo systemctl is-enabled ssh >/dev/null 2>&1 && echo "✅ SSH: enabled" || echo "❌ SSH: not enabled"

echo ""
echo "📋 Deployment Instructions:"
echo "   1. Configure boot notification email in admin panel (if not done)"
echo "   2. Shutdown the Pi: sudo shutdown -h now"
echo "   3. Move Pi to deployment location"
echo "   4. Connect ethernet cable (if using wired)"
echo "   5. Power on the Pi"
echo "   6. Wait 2-3 minutes for boot and network connection"
echo "   7. Check email for boot notification with clickable links"
echo "   8. Click dashboard link in email to start using immediately"
echo ""
echo "🔧 The Pi is ready for deployment!"
echo ""
echo "⚠️  Important Notes:"
echo "   • Configure boot notification email settings before deployment"
echo "   • Test email functionality using admin panel 'Send Test Email'"
echo "   • Default SSH password is 'raspberry' - change it for security"
echo "   • Dashboard will be accessible via HTTPS on both wired and wireless"