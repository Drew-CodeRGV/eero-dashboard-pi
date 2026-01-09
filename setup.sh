#!/bin/bash

# Eero Dashboard Setup Script
# For manual installation after git clone

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get current directory
INSTALL_DIR="$(pwd)"
SERVICE_NAME="eero-dashboard"
SERVICE_USER="$USER"

print_status "Setting up Eero Dashboard from $INSTALL_DIR"

# Create virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip
pip install flask flask-cors requests pytz pathlib

# Create configuration directory
print_status "Creating configuration directory..."
mkdir -p "$HOME/.eero-dashboard"

# Make dashboard executable
chmod +x dashboard.py

# Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=Eero Network Dashboard
After=network.target
Wants=network.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}
Environment=PATH=${INSTALL_DIR}/venv/bin
ExecStart=${INSTALL_DIR}/venv/bin/python ${INSTALL_DIR}/dashboard.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

# Wait for service to start
sleep 3

if sudo systemctl is-active --quiet ${SERVICE_NAME}; then
    print_success "Dashboard service started successfully"
else
    print_error "Failed to start dashboard service"
    sudo systemctl status ${SERVICE_NAME} --no-pager
    exit 1
fi

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo
echo "=================================================================="
echo -e "${GREEN}🎉 Setup Complete! 🎉${NC}"
echo "=================================================================="
echo
echo "📊 Access your dashboard at:"
echo "   http://localhost:5000"
echo "   http://${IP_ADDRESS}:5000"
echo
echo "🔧 Service commands:"
echo "   sudo systemctl status eero-dashboard"
echo "   sudo systemctl stop eero-dashboard"
echo "   sudo systemctl start eero-dashboard"
echo
echo "📝 View logs:"
echo "   sudo journalctl -u eero-dashboard -f"
echo
echo "=================================================================="