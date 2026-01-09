#!/bin/bash

# Force Update Script - Downloads the latest fixed dashboard.py

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

echo -e "${BLUE}🔄 Force Update Eero Dashboard${NC}"
echo "User: $CURRENT_USER"
echo "Install Dir: $INSTALL_DIR"
echo

if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "Installation directory not found: $INSTALL_DIR"
    exit 1
fi

# Stop service
print_status "Stopping service..."
sudo systemctl stop eero-dashboard 2>/dev/null || true

# Backup current file
print_status "Backing up current dashboard.py..."
if [[ -f "$INSTALL_DIR/dashboard.py" ]]; then
    cp "$INSTALL_DIR/dashboard.py" "$INSTALL_DIR/dashboard.py.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Backup created"
fi

# Force download the latest dashboard.py
print_status "Downloading latest dashboard.py from GitHub..."
cd "$INSTALL_DIR"

# Download the fixed version directly
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/dashboard.py -o dashboard.py.new

if [[ $? -eq 0 ]]; then
    print_success "Downloaded latest dashboard.py"
    
    # Replace the old file
    mv dashboard.py.new dashboard.py
    chmod +x dashboard.py
    
    # Fix ownership
    sudo chown $CURRENT_USER:$CURRENT_USER dashboard.py
    
    print_success "File updated and permissions set"
else
    print_error "Failed to download latest dashboard.py"
    exit 1
fi

# Test the syntax
print_status "Testing Python syntax..."
cd "$INSTALL_DIR"
source venv/bin/activate

if python3 -m py_compile dashboard.py; then
    print_success "✅ Python syntax is valid"
else
    print_error "❌ Python syntax error still exists"
    deactivate
    exit 1
fi

deactivate

# Restart service
print_status "Restarting service..."
sudo systemctl daemon-reload
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
    sleep 2
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_success "✅ Dashboard is responding!"
        echo
        echo "🎯 Dashboard is fully operational!"
    else
        print_status "Service running, dashboard may need a moment to start..."
        echo "   Check in a few seconds: http://$IP_ADDRESS:5000"
    fi
else
    print_error "❌ Service failed to start"
    echo
    print_status "Checking for errors..."
    sudo journalctl -u eero-dashboard -n 10 --no-pager
    exit 1
fi

echo
print_success "Force update complete!"