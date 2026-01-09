#!/bin/bash

# Setup Boot Notification Service for Eero Dashboard
# This script installs and configures the boot notification service

set -e

echo "🔧 Setting up Boot Notification Service..."

# Check if running as root for systemd operations
if [[ $EUID -eq 0 ]]; then
    echo "❌ Please run this script as the wifi user, not as root"
    echo "   The script will use sudo when needed"
    exit 1
fi

# Ensure we're in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 Working directory: $SCRIPT_DIR"

# Make boot notification script executable
echo "🔧 Making boot notification script executable..."
chmod +x boot-notification.py

# Install systemd service
echo "🔧 Installing systemd service..."
sudo cp boot-notification.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "🔧 Enabling boot notification service..."
sudo systemctl enable boot-notification.service

# Check service status
echo "📊 Service status:"
sudo systemctl status boot-notification.service --no-pager || true

echo ""
echo "✅ Boot notification service setup complete!"
echo ""
echo "📋 Service Management Commands:"
echo "   Start service:    sudo systemctl start boot-notification.service"
echo "   Stop service:     sudo systemctl stop boot-notification.service"
echo "   Check status:     sudo systemctl status boot-notification.service"
echo "   View logs:        sudo journalctl -u boot-notification.service -f"
echo "   Disable service:  sudo systemctl disable boot-notification.service"
echo ""
echo "🔧 Configuration:"
echo "   Configure email settings in the dashboard admin panel"
echo "   Test notification: Use the 'Test Boot Notification' button in admin panel"
echo ""
echo "⚠️  Note: The service will run automatically on next boot"
echo "   To test immediately: sudo systemctl start boot-notification.service"