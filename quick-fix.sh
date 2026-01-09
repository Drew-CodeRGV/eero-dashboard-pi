#!/bin/bash

# Eero Dashboard - Quick Fix Script
# Fixes the most common installation issues

set -e

# Colors
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

# Get current user and directories
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$USER_HOME/eero-dashboard"

echo -e "${BLUE}🔧 Eero Dashboard Quick Fix${NC}"
echo "User: $CURRENT_USER"
echo "Install Dir: $INSTALL_DIR"
echo

# Stop service
print_status "Stopping service..."
sudo systemctl stop eero-dashboard 2>/dev/null || true

# Fix permissions
print_status "Fixing file permissions..."
if [[ -d "$INSTALL_DIR" ]]; then
    sudo chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/dashboard.py"
    print_success "Install directory permissions fixed"
fi

if [[ -d "$USER_HOME/.eero-dashboard" ]]; then
    sudo chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.eero-dashboard"
    print_success "Config directory permissions fixed"
fi

# Reinstall dependencies
print_status "Checking and fixing Python dependencies..."
if [[ -f "$INSTALL_DIR/venv/bin/activate" ]]; then
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    pip install --upgrade pip
    pip install flask flask-cors requests pytz pathlib
    
    deactivate
    print_success "Dependencies updated"
else
    print_error "Virtual environment not found!"
    exit 1
fi

# Update service file if needed
print_status "Checking service file..."
SERVICE_FILE="/etc/systemd/system/eero-dashboard.service"

# Create correct service file
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Eero Network Dashboard
After=network.target
Wants=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/dashboard.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

print_success "Service file updated"

# Reload and restart service
print_status "Restarting service..."
sudo systemctl daemon-reload
sudo systemctl enable eero-dashboard
sudo systemctl start eero-dashboard

# Wait and check status
sleep 5

if sudo systemctl is-active --quiet eero-dashboard; then
    print_success "🎉 Service is now running!"
    
    # Get IP for access info
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    echo
    echo "🚀 Access your dashboard:"
    echo "   Local:  http://localhost:5000"
    echo "   Remote: http://$IP_ADDRESS:5000"
    echo
    
    # Test HTTP response
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_success "✅ Dashboard is responding!"
    else
        print_status "Service running, dashboard may need a moment to start..."
    fi
else
    print_error "❌ Service failed to start"
    echo "Run the full diagnostic script for more details:"
    echo "curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/diagnose-and-fix.sh | bash"
    exit 1
fi

echo
print_success "Quick fix complete!"