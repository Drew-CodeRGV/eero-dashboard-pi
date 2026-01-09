#!/bin/bash

# Eero Dashboard for Raspberry Pi - Installation Script
# Version: 7.0.14
# Description: Automated installation script for Raspberry Pi

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/eero-dashboard"
SERVICE_NAME="eero-dashboard"
SERVICE_USER="$USER"
PORT=5000

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running on Raspberry Pi
check_raspberry_pi() {
    if [[ ! -f /proc/device-tree/model ]] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        print_warning "This script is designed for Raspberry Pi, but can work on other Linux systems"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        PI_MODEL=$(cat /proc/device-tree/model)
        print_success "Detected: $PI_MODEL"
    fi
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Python version
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    print_success "Python $PYTHON_VERSION detected"
    
    # Check available space
    AVAILABLE_SPACE=$(df -BM "$HOME" | awk 'NR==2 {print $4}' | sed 's/M//')
    if [[ $AVAILABLE_SPACE -lt 100 ]]; then
        print_error "Insufficient disk space. At least 100MB required, only ${AVAILABLE_SPACE}MB available"
        exit 1
    fi
    
    print_success "System requirements met"
}

# Function to update system packages
update_system() {
    print_status "Updating system packages..."
    
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y python3-pip python3-venv git curl
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y python3-pip python3-venv git curl
    else
        print_warning "Package manager not recognized. Please install python3-pip, python3-venv, git, and curl manually"
    fi
    
    print_success "System packages updated"
}

# Function to download and install dashboard
install_dashboard() {
    print_status "Installing Eero Dashboard..."
    
    # Remove existing installation if present
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Existing installation found. Backing up configuration..."
        if [[ -d "$HOME/.eero-dashboard" ]]; then
            cp -r "$HOME/.eero-dashboard" "$HOME/.eero-dashboard.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repository
    git clone https://github.com/yourusername/eero-dashboard-pi.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Install Python dependencies
    pip install --upgrade pip
    pip install flask flask-cors requests pytz pathlib
    
    # Create configuration directory
    mkdir -p "$HOME/.eero-dashboard"
    
    # Set permissions
    chmod +x dashboard.py
    
    print_success "Dashboard installed successfully"
}

# Function to create systemd service
create_service() {
    print_status "Creating systemd service..."
    
    # Create service file
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

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable ${SERVICE_NAME}
    
    print_success "Systemd service created and enabled"
}

# Function to configure firewall (optional)
configure_firewall() {
    if command -v ufw &> /dev/null; then
        read -p "Configure firewall to allow dashboard access? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Configuring firewall..."
            sudo ufw allow ${PORT}/tcp comment "Eero Dashboard"
            print_success "Firewall configured"
        fi
    fi
}

# Function to create desktop shortcut
create_desktop_shortcut() {
    if [[ -d "$HOME/Desktop" ]]; then
        print_status "Creating desktop shortcut..."
        
        cat > "$HOME/Desktop/Eero Dashboard.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Eero Dashboard
Comment=Network monitoring dashboard
Exec=xdg-open http://localhost:${PORT}
Icon=network-workgroup
Terminal=false
Categories=Network;
EOF
        
        chmod +x "$HOME/Desktop/Eero Dashboard.desktop"
        print_success "Desktop shortcut created"
    fi
}

# Function to start services
start_services() {
    print_status "Starting Eero Dashboard service..."
    
    sudo systemctl start ${SERVICE_NAME}
    
    # Wait for service to start
    sleep 3
    
    if sudo systemctl is-active --quiet ${SERVICE_NAME}; then
        print_success "Dashboard service started successfully"
    else
        print_error "Failed to start dashboard service"
        print_status "Checking service status..."
        sudo systemctl status ${SERVICE_NAME} --no-pager
        exit 1
    fi
}

# Function to display completion message
show_completion() {
    local IP_ADDRESS=$(hostname -I | awk '{print $1}')
    
    echo
    echo "=================================================================="
    echo -e "${GREEN}🎉 Eero Dashboard Installation Complete! 🎉${NC}"
    echo "=================================================================="
    echo
    echo "📊 Dashboard Access:"
    echo "   Local:   http://localhost:${PORT}"
    echo "   Network: http://${IP_ADDRESS}:${PORT}"
    echo
    echo "🔧 Service Management:"
    echo "   Status:  sudo systemctl status ${SERVICE_NAME}"
    echo "   Stop:    sudo systemctl stop ${SERVICE_NAME}"
    echo "   Start:   sudo systemctl start ${SERVICE_NAME}"
    echo "   Logs:    sudo journalctl -u ${SERVICE_NAME} -f"
    echo
    echo "⚙️  Configuration:"
    echo "   Config:  ~/.eero-dashboard/config.json"
    echo "   Logs:    ~/.eero-dashboard/dashboard.log"
    echo
    echo "🚀 Next Steps:"
    echo "   1. Open the dashboard in your browser"
    echo "   2. Click the π button to access admin panel"
    echo "   3. Add your Eero networks and authenticate"
    echo "   4. Enjoy monitoring your network!"
    echo
    echo "📚 Documentation: https://github.com/yourusername/eero-dashboard-pi"
    echo "🐛 Issues: https://github.com/yourusername/eero-dashboard-pi/issues"
    echo
    echo "=================================================================="
}

# Main installation function
main() {
    echo "=================================================================="
    echo "🥧 Eero Dashboard for Raspberry Pi - Installation Script"
    echo "=================================================================="
    echo
    
    check_raspberry_pi
    check_requirements
    update_system
    install_dashboard
    create_service
    configure_firewall
    create_desktop_shortcut
    start_services
    show_completion
}

# Run main function
main "$@"