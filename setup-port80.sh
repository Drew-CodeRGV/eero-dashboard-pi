#!/bin/bash

# Setup Eero Dashboard for Port 80
# This script configures the dashboard to run on port 80 (standard HTTP)

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${BLUE}🌐 Eero Dashboard Port 80 Setup${NC}"
echo "This will configure the dashboard to run on port 80 (standard HTTP)"
echo

# Check if running as root for this setup
if [[ $EUID -eq 0 ]]; then
    print_error "Don't run this script as root. Run as regular user (pi/wifi)."
    exit 1
fi

# Get current user and directories
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$USER_HOME/eero-dashboard"

if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "Dashboard not found. Please install first with:"
    echo "curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/install.sh | bash"
    exit 1
fi

print_status "Current user: $CURRENT_USER"
print_status "Install directory: $INSTALL_DIR"

# Stop current service
print_status "Stopping current service..."
sudo systemctl stop eero-dashboard 2>/dev/null || true

# Check if port 80 is available
print_status "Checking port 80 availability..."
if sudo netstat -tlnp | grep -q ":80 "; then
    print_warning "Port 80 is already in use:"
    sudo netstat -tlnp | grep ":80 "
    echo
    read -p "Continue anyway? This may cause conflicts. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled"
        exit 1
    fi
fi

# Update dashboard.py to use port 80
print_status "Updating dashboard.py for port 80..."
cd "$INSTALL_DIR"

# Backup current file
cp dashboard.py dashboard.py.backup.port5000

# Update port in dashboard.py
sed -i 's/port=5000/port=80/g' dashboard.py

if grep -q "port=80" dashboard.py; then
    print_success "Dashboard updated to use port 80"
else
    print_error "Failed to update port in dashboard.py"
    exit 1
fi

# Create new systemd service for port 80
print_status "Creating systemd service for port 80..."
sudo tee /etc/systemd/system/eero-dashboard.service > /dev/null <<EOF
[Unit]
Description=Eero Network Dashboard (Port 80)
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
Environment=HOME=/root
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/dashboard.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Allow port 80 access
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=false

[Install]
WantedBy=multi-user.target
EOF

print_success "Service file created for port 80"

# Set up root config directory (since service runs as root)
print_status "Setting up root configuration directory..."
sudo mkdir -p /root/.eero-dashboard

# Copy existing config if it exists
if [[ -d "$USER_HOME/.eero-dashboard" ]]; then
    sudo cp -r "$USER_HOME/.eero-dashboard/"* /root/.eero-dashboard/ 2>/dev/null || true
    print_success "Copied existing configuration to root directory"
fi

# Set proper permissions
sudo chown -R root:root /root/.eero-dashboard
sudo chmod 700 /root/.eero-dashboard

# Reload and start service
print_status "Starting service on port 80..."
sudo systemctl daemon-reload
sudo systemctl enable eero-dashboard
sudo systemctl start eero-dashboard

# Wait for service to start
sleep 5

# Check service status
if sudo systemctl is-active --quiet eero-dashboard; then
    print_success "🎉 Service is running on port 80!"
    
    # Get IP address
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    
    echo
    echo "🌐 Dashboard Access URLs:"
    echo "   Local:  http://localhost"
    echo "   Remote: http://$IP_ADDRESS"
    echo
    
    # Test HTTP response
    sleep 3
    if curl -s http://localhost/health > /dev/null 2>&1; then
        print_success "✅ Dashboard is responding on port 80!"
        echo
        print_success "🎯 Setup complete! Your dashboard is now accessible without a port number."
    else
        print_warning "Service is running but dashboard may need more time to start"
        echo "   Try accessing http://$IP_ADDRESS in a few moments"
    fi
    
    echo
    echo "📝 Notes:"
    echo "   - Dashboard now runs as root (required for port 80)"
    echo "   - Configuration is stored in /root/.eero-dashboard"
    echo "   - Your original port 5000 config is backed up"
    
else
    print_error "❌ Service failed to start"
    echo
    print_status "Checking service logs..."
    sudo journalctl -u eero-dashboard -n 20 --no-pager
    
    echo
    print_status "To revert to port 5000:"
    echo "   cp dashboard.py.backup.port5000 dashboard.py"
    echo "   sudo systemctl restart eero-dashboard"
fi

echo
print_success "Port 80 setup complete!"