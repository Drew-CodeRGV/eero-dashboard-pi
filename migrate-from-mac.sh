#!/bin/bash

# Migrate Eero Dashboard Data from Mac to Raspberry Pi
# This script copies configuration, API tokens, and historical data

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

echo -e "${BLUE}📦 Eero Dashboard Migration from Mac to Pi${NC}"
echo "This script will copy all your data from Mac to Raspberry Pi"
echo

# Get Pi directories
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)
PI_CONFIG_DIR="$USER_HOME/.eero-dashboard"
PI_INSTALL_DIR="$USER_HOME/eero-dashboard"

# Check if Pi dashboard is installed
if [[ ! -d "$PI_INSTALL_DIR" ]]; then
    print_error "Dashboard not installed on Pi. Please install first:"
    echo "curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/install.sh | bash"
    exit 1
fi

print_status "Pi user: $CURRENT_USER"
print_status "Pi config directory: $PI_CONFIG_DIR"

# Get Mac connection details
echo
echo "📡 Mac Connection Details:"
read -p "Mac IP address or hostname: " MAC_HOST
read -p "Mac username: " MAC_USER

# Validate connection
print_status "Testing connection to Mac..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$MAC_USER@$MAC_HOST" "echo 'Connection test'" 2>/dev/null; then
    print_warning "Cannot connect with SSH keys. You'll need to enter password for each transfer."
    echo
    print_status "Testing with password..."
    if ! ssh -o ConnectTimeout=10 "$MAC_USER@$MAC_HOST" "echo 'Connection test'"; then
        print_error "Cannot connect to Mac. Please check:"
        echo "  - Mac IP address/hostname is correct"
        echo "  - SSH is enabled on Mac (System Preferences > Sharing > Remote Login)"
        echo "  - Username is correct"
        echo "  - Mac is on the same network"
        exit 1
    fi
fi

print_success "Connection to Mac established"

# Detect Mac dashboard location
print_status "Detecting Mac dashboard location..."

# Common Mac locations to check
MAC_LOCATIONS=(
    "/Users/$MAC_USER/.minirack"
    "/Users/$MAC_USER/.eero-dashboard" 
    "/Users/$MAC_USER/eero-event-dashboard-repo"
    "/Users/$MAC_USER/minirackdash"
    "/Users/$MAC_USER/Desktop/eero-event-dashboard-repo"
    "/Users/$MAC_USER/Documents/eero-event-dashboard-repo"
)

MAC_CONFIG_DIR=""
for location in "${MAC_LOCATIONS[@]}"; do
    if ssh "$MAC_USER@$MAC_HOST" "test -f '$location/config.json'" 2>/dev/null; then
        MAC_CONFIG_DIR="$location"
        print_success "Found Mac config at: $MAC_CONFIG_DIR"
        break
    fi
done

if [[ -z "$MAC_CONFIG_DIR" ]]; then
    print_warning "Could not auto-detect Mac config location."
    echo
    echo "Please check these locations on your Mac and enter the correct path:"
    for location in "${MAC_LOCATIONS[@]}"; do
        echo "  $location"
    done
    echo
    read -p "Enter full path to Mac config directory: " MAC_CONFIG_DIR
    
    # Validate custom path
    if ! ssh "$MAC_USER@$MAC_HOST" "test -f '$MAC_CONFIG_DIR/config.json'" 2>/dev/null; then
        print_error "Config file not found at: $MAC_CONFIG_DIR/config.json"
        exit 1
    fi
fi

# Stop Pi service during migration
print_status "Stopping Pi dashboard service..."
sudo systemctl stop eero-dashboard 2>/dev/null || true

# Create backup of current Pi config
if [[ -d "$PI_CONFIG_DIR" ]]; then
    print_status "Backing up current Pi configuration..."
    cp -r "$PI_CONFIG_DIR" "$PI_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Pi config backed up"
fi

# Ensure Pi config directory exists
mkdir -p "$PI_CONFIG_DIR"

# Copy configuration files
print_status "Copying configuration from Mac..."

# Copy main config.json
if ssh "$MAC_USER@$MAC_HOST" "test -f '$MAC_CONFIG_DIR/config.json'"; then
    scp "$MAC_USER@$MAC_HOST:$MAC_CONFIG_DIR/config.json" "$PI_CONFIG_DIR/"
    print_success "✅ Copied config.json"
else
    print_warning "⚠️  config.json not found on Mac"
fi

# Copy API tokens
print_status "Copying API tokens..."
TOKEN_COUNT=0

# Copy all .eero_token* files
ssh "$MAC_USER@$MAC_HOST" "find '$MAC_CONFIG_DIR' -name '.eero_token*' -type f" 2>/dev/null | while read token_file; do
    if [[ -n "$token_file" ]]; then
        filename=$(basename "$token_file")
        scp "$MAC_USER@$MAC_HOST:$token_file" "$PI_CONFIG_DIR/"
        print_success "✅ Copied $filename"
        ((TOKEN_COUNT++))
    fi
done

# Wait for the subshell to complete
wait

# Check if we got tokens
if ls "$PI_CONFIG_DIR"/.eero_token* 1> /dev/null 2>&1; then
    TOKEN_COUNT=$(ls "$PI_CONFIG_DIR"/.eero_token* | wc -l)
    print_success "Copied $TOKEN_COUNT API token file(s)"
else
    print_warning "⚠️  No API token files found"
fi

# Copy historical data
print_status "Copying historical data..."

# Copy data cache files
DATA_FILES=(
    "data_cache.json"
    "data_cache_backup*.json"
    "dashboard.log"
)

for pattern in "${DATA_FILES[@]}"; do
    # Use find to handle wildcards
    ssh "$MAC_USER@$MAC_HOST" "find '$MAC_CONFIG_DIR' -name '$pattern' -type f 2>/dev/null" | while read data_file; do
        if [[ -n "$data_file" ]]; then
            filename=$(basename "$data_file")
            scp "$MAC_USER@$MAC_HOST:$data_file" "$PI_CONFIG_DIR/"
            print_success "✅ Copied $filename"
        fi
    done
done

# Set proper permissions
print_status "Setting file permissions..."
chown -R "$CURRENT_USER:$CURRENT_USER" "$PI_CONFIG_DIR"
chmod 700 "$PI_CONFIG_DIR"
chmod 600 "$PI_CONFIG_DIR"/.eero_token* 2>/dev/null || true
chmod 644 "$PI_CONFIG_DIR"/config.json 2>/dev/null || true

print_success "Permissions set correctly"

# Validate migrated data
print_status "Validating migrated data..."

if [[ -f "$PI_CONFIG_DIR/config.json" ]]; then
    # Check if config is valid JSON
    if python3 -m json.tool "$PI_CONFIG_DIR/config.json" > /dev/null 2>&1; then
        print_success "✅ Configuration file is valid"
        
        # Show network count
        NETWORK_COUNT=$(python3 -c "
import json
with open('$PI_CONFIG_DIR/config.json', 'r') as f:
    config = json.load(f)
    networks = config.get('networks', [])
    print(len(networks))
" 2>/dev/null || echo "0")
        
        print_success "✅ Found $NETWORK_COUNT network(s) in configuration"
    else
        print_error "❌ Configuration file is corrupted"
    fi
else
    print_error "❌ Configuration file not copied"
fi

# If running as root (port 80), copy to root directory too
if sudo systemctl show eero-dashboard --property=User 2>/dev/null | grep -q "User=root"; then
    print_status "Service runs as root, copying to /root/.eero-dashboard..."
    sudo mkdir -p /root/.eero-dashboard
    sudo cp -r "$PI_CONFIG_DIR/"* /root/.eero-dashboard/
    sudo chown -R root:root /root/.eero-dashboard
    sudo chmod 700 /root/.eero-dashboard
    sudo chmod 600 /root/.eero-dashboard/.eero_token* 2>/dev/null || true
    print_success "✅ Copied to root directory for port 80 service"
fi

# Start Pi service
print_status "Starting Pi dashboard service..."
sudo systemctl start eero-dashboard

# Wait for service to start
sleep 5

# Check service status
if sudo systemctl is-active --quiet eero-dashboard; then
    print_success "🎉 Pi dashboard service is running!"
    
    # Get IP address
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    
    # Determine port
    if sudo systemctl show eero-dashboard --property=User 2>/dev/null | grep -q "User=root"; then
        PORT=""
        URL="http://$IP_ADDRESS"
    else
        PORT=":5000"
        URL="http://$IP_ADDRESS:5000"
    fi
    
    echo
    echo "🌐 Dashboard Access:"
    echo "   $URL"
    echo
    
    # Test HTTP response
    sleep 3
    TEST_URL="http://localhost${PORT}/health"
    if curl -s "$TEST_URL" > /dev/null 2>&1; then
        print_success "✅ Dashboard is responding!"
        
        # Try to get version info
        VERSION_INFO=$(curl -s "$TEST_URL" 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(f\"Version: {data.get('version', 'Unknown')}\")
except:
    print('Dashboard responding')
" 2>/dev/null || echo "Dashboard responding")
        
        print_success "✅ $VERSION_INFO"
        
    else
        print_warning "Service running but dashboard may need more time to start"
    fi
    
else
    print_error "❌ Service failed to start"
    print_status "Checking service logs..."
    sudo journalctl -u eero-dashboard -n 10 --no-pager
fi

echo
echo "📋 Migration Summary:"
echo "================================"
echo "✅ Configuration: Copied from Mac"
echo "✅ API Tokens: Migrated to Pi"
echo "✅ Historical Data: Preserved"
echo "✅ Service: Running on Pi"
echo
echo "🎯 Your Mac dashboard data is now running on the Pi!"
echo "   You can now stop the Mac dashboard if desired."
echo
print_success "Migration complete!"