#!/bin/bash

# Eero Dashboard - Diagnostic and Fix Script
# Run this script on your Raspberry Pi to diagnose and fix service issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

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

# Get current user and home directory
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$USER_HOME/eero-dashboard"
CONFIG_DIR="$USER_HOME/.eero-dashboard"

print_header "🔍 EERO DASHBOARD DIAGNOSTIC SCRIPT"
echo "User: $CURRENT_USER"
echo "Home: $USER_HOME"
echo "Install Dir: $INSTALL_DIR"
echo "Config Dir: $CONFIG_DIR"
echo

# Function to run command and capture output
run_diagnostic() {
    local title="$1"
    local command="$2"
    local critical="$3"
    
    print_status "Running: $title"
    echo "Command: $command"
    echo "----------------------------------------"
    
    if eval "$command" 2>&1; then
        print_success "$title - OK"
    else
        if [[ "$critical" == "critical" ]]; then
            print_error "$title - FAILED (Critical)"
        else
            print_warning "$title - FAILED (Non-critical)"
        fi
    fi
    echo
}

# 1. System Information
print_header "📊 SYSTEM INFORMATION"
run_diagnostic "System Info" "uname -a"
run_diagnostic "Python Version" "python3 --version"
run_diagnostic "Disk Space" "df -h $USER_HOME"
run_diagnostic "Memory Usage" "free -h"
echo

# 2. Installation Check
print_header "📁 INSTALLATION CHECK"
run_diagnostic "Install Directory Exists" "ls -la $INSTALL_DIR" "critical"
run_diagnostic "Dashboard Script Exists" "ls -la $INSTALL_DIR/dashboard.py" "critical"
run_diagnostic "Virtual Environment Exists" "ls -la $INSTALL_DIR/venv" "critical"
run_diagnostic "Config Directory Exists" "ls -la $CONFIG_DIR"
echo

# 3. File Permissions
print_header "🔒 FILE PERMISSIONS"
if [[ -d "$INSTALL_DIR" ]]; then
    run_diagnostic "Install Directory Permissions" "ls -ld $INSTALL_DIR"
    run_diagnostic "Dashboard Script Permissions" "ls -l $INSTALL_DIR/dashboard.py"
    run_diagnostic "Virtual Environment Permissions" "ls -ld $INSTALL_DIR/venv"
fi

if [[ -d "$CONFIG_DIR" ]]; then
    run_diagnostic "Config Directory Permissions" "ls -ld $CONFIG_DIR"
fi
echo

# 4. Python Dependencies
print_header "🐍 PYTHON DEPENDENCIES"
if [[ -f "$INSTALL_DIR/venv/bin/activate" ]]; then
    print_status "Testing Python dependencies..."
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    run_diagnostic "Flask Import" "python -c 'import flask; print(f\"Flask {flask.__version__}\")'"
    run_diagnostic "Requests Import" "python -c 'import requests; print(f\"Requests {requests.__version__}\")'"
    run_diagnostic "Pytz Import" "python -c 'import pytz; print(\"Pytz OK\")'"
    run_diagnostic "Flask-CORS Import" "python -c 'import flask_cors; print(\"Flask-CORS OK\")'"
    run_diagnostic "Pathlib Import" "python -c 'from pathlib import Path; print(\"Pathlib OK\")'"
    
    deactivate
else
    print_error "Virtual environment not found!"
fi
echo

# 5. Network and Port Check
print_header "🌐 NETWORK CHECK"
run_diagnostic "Port 80 Usage" "sudo netstat -tlnp | grep :80 || echo 'Port 80 is free'"
run_diagnostic "Network Connectivity" "ping -c 2 8.8.8.8"
run_diagnostic "HTTPS Connectivity" "curl -s -o /dev/null -w '%{http_code}' https://api-user.e2ro.com || echo 'HTTPS test failed'"
echo

# 6. Service Status
print_header "⚙️ SERVICE STATUS"
run_diagnostic "Service File Exists" "sudo ls -la /etc/systemd/system/eero-dashboard.service"
run_diagnostic "Service Status" "sudo systemctl status eero-dashboard --no-pager -l"
run_diagnostic "Service Logs (Last 20 lines)" "sudo journalctl -u eero-dashboard -n 20 --no-pager"
echo

# 7. Manual Test
print_header "🧪 MANUAL TEST"
if [[ -f "$INSTALL_DIR/dashboard.py" && -f "$INSTALL_DIR/venv/bin/activate" ]]; then
    print_status "Attempting to run dashboard manually for 10 seconds..."
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # Run dashboard in background for 10 seconds
    timeout 10s python dashboard.py &
    DASHBOARD_PID=$!
    
    sleep 3
    
    # Test if it's responding
    if curl -s http://localhost:80/health > /dev/null 2>&1; then
        print_success "Dashboard responds to HTTP requests!"
        curl -s http://localhost:80/health | python -m json.tool 2>/dev/null || echo "Health check response received"
    else
        print_warning "Dashboard not responding to HTTP requests"
    fi
    
    # Kill the background process
    kill $DASHBOARD_PID 2>/dev/null || true
    wait $DASHBOARD_PID 2>/dev/null || true
    
    deactivate
else
    print_error "Cannot run manual test - files missing"
fi
echo

# 8. Automatic Fixes
print_header "🔧 AUTOMATIC FIXES"

# Fix 1: File Permissions
if [[ -d "$INSTALL_DIR" ]]; then
    print_status "Fixing file permissions..."
    sudo chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/dashboard.py" 2>/dev/null || true
    print_success "File permissions fixed"
fi

if [[ -d "$CONFIG_DIR" ]]; then
    sudo chown -R $CURRENT_USER:$CURRENT_USER "$CONFIG_DIR" 2>/dev/null || true
    print_success "Config directory permissions fixed"
fi

# Fix 2: Service File User
print_status "Checking service file user configuration..."
if sudo grep -q "User=$CURRENT_USER" /etc/systemd/system/eero-dashboard.service 2>/dev/null; then
    print_success "Service file user is correct"
else
    print_warning "Service file may have wrong user. Current user: $CURRENT_USER"
    print_status "Service file contents:"
    sudo cat /etc/systemd/system/eero-dashboard.service 2>/dev/null || print_error "Cannot read service file"
fi

# Fix 3: Reinstall Dependencies (if needed)
if [[ -f "$INSTALL_DIR/venv/bin/activate" ]]; then
    print_status "Checking if dependency reinstall is needed..."
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    if ! python -c "import flask, requests, pytz, flask_cors" 2>/dev/null; then
        print_warning "Dependencies missing, reinstalling..."
        pip install --upgrade pip
        pip install flask flask-cors requests pytz
        print_success "Dependencies reinstalled"
    else
        print_success "Dependencies are OK"
    fi
    
    deactivate
fi

# Fix 4: Restart Service
print_status "Restarting service..."
sudo systemctl daemon-reload
sudo systemctl stop eero-dashboard 2>/dev/null || true
sleep 2
sudo systemctl start eero-dashboard

sleep 3

# Final Status Check
print_header "✅ FINAL STATUS CHECK"
if sudo systemctl is-active --quiet eero-dashboard; then
    print_success "🎉 Service is now running!"
    
    # Test HTTP response
    sleep 2
    if curl -s http://localhost:80/health > /dev/null 2>&1; then
        print_success "🌐 Dashboard is responding to HTTP requests!"
        
        # Get IP address for remote access
        IP_ADDRESS=$(hostname -I | awk '{print $1}')
        echo
        echo "🚀 Dashboard Access URLs:"
        echo "   Local:  http://localhost"
        echo "   Remote: http://$IP_ADDRESS"
        echo
        print_success "Dashboard is fully operational!"
    else
        print_warning "Service running but not responding to HTTP requests yet (may need more time)"
    fi
else
    print_error "❌ Service is still not running"
    echo
    print_status "Final service status:"
    sudo systemctl status eero-dashboard --no-pager -l
    echo
    print_status "Recent logs:"
    sudo journalctl -u eero-dashboard -n 10 --no-pager
fi

print_header "📋 DIAGNOSTIC COMPLETE"
echo "If the service is still not working, please share this output for further assistance."
echo "You can also check logs with: sudo journalctl -u eero-dashboard -f"
echo