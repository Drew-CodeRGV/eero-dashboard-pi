#!/bin/bash

# Export Eero Dashboard Data from Mac
# Run this script ON THE MAC to prepare data for Pi migration

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

echo -e "${BLUE}📤 Export Mac Dashboard Data${NC}"
echo "This script prepares your Mac dashboard data for Pi migration"
echo

# Find dashboard data location
POSSIBLE_LOCATIONS=(
    "$HOME/.minirack"
    "$HOME/.eero-dashboard"
    "$HOME/eero-event-dashboard-repo"
    "$HOME/minirackdash"
    "$HOME/Desktop/eero-event-dashboard-repo"
    "$HOME/Documents/eero-event-dashboard-repo"
)

CONFIG_DIR=""
for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [[ -f "$location/config.json" ]]; then
        CONFIG_DIR="$location"
        print_success "Found dashboard data at: $CONFIG_DIR"
        break
    fi
done

if [[ -z "$CONFIG_DIR" ]]; then
    print_error "Could not find dashboard configuration."
    echo "Please check these locations:"
    for location in "${POSSIBLE_LOCATIONS[@]}"; do
        echo "  $location"
    done
    echo
    read -p "Enter full path to config directory: " CONFIG_DIR
    
    if [[ ! -f "$CONFIG_DIR/config.json" ]]; then
        print_error "Config file not found at: $CONFIG_DIR/config.json"
        exit 1
    fi
fi

# Create export directory
EXPORT_DIR="$HOME/Desktop/eero-dashboard-export"
mkdir -p "$EXPORT_DIR"

print_status "Exporting data to: $EXPORT_DIR"

# Copy configuration
if [[ -f "$CONFIG_DIR/config.json" ]]; then
    cp "$CONFIG_DIR/config.json" "$EXPORT_DIR/"
    print_success "✅ Exported config.json"
    
    # Show network info
    if command -v python3 >/dev/null 2>&1; then
        NETWORK_INFO=$(python3 -c "
import json
try:
    with open('$CONFIG_DIR/config.json', 'r') as f:
        config = json.load(f)
        networks = config.get('networks', [])
        print(f'{len(networks)} networks configured')
        for i, net in enumerate(networks, 1):
            name = net.get('name', 'Unknown')
            net_id = net.get('id', 'Unknown')
            active = net.get('active', True)
            status = 'Active' if active else 'Inactive'
            print(f'  {i}. {name} (ID: {net_id}) - {status}')
except Exception as e:
    print('Config file found but could not parse')
" 2>/dev/null)
        echo "$NETWORK_INFO"
    fi
fi

# Copy API tokens
print_status "Copying API tokens..."
TOKEN_COUNT=0
for token_file in "$CONFIG_DIR"/.eero_token*; do
    if [[ -f "$token_file" ]]; then
        cp "$token_file" "$EXPORT_DIR/"
        filename=$(basename "$token_file")
        print_success "✅ Exported $filename"
        ((TOKEN_COUNT++))
    fi
done

if [[ $TOKEN_COUNT -eq 0 ]]; then
    print_error "❌ No API tokens found"
else
    print_success "✅ Exported $TOKEN_COUNT API token(s)"
fi

# Copy historical data
print_status "Copying historical data..."
DATA_COUNT=0

# Copy data cache files
for data_file in "$CONFIG_DIR"/data_cache*.json; do
    if [[ -f "$data_file" ]]; then
        cp "$data_file" "$EXPORT_DIR/"
        filename=$(basename "$data_file")
        print_success "✅ Exported $filename"
        ((DATA_COUNT++))
    fi
done

# Copy logs
if [[ -f "$CONFIG_DIR/dashboard.log" ]]; then
    cp "$CONFIG_DIR/dashboard.log" "$EXPORT_DIR/"
    print_success "✅ Exported dashboard.log"
    ((DATA_COUNT++))
fi

if [[ $DATA_COUNT -eq 0 ]]; then
    print_warning "⚠️  No historical data files found"
else
    print_success "✅ Exported $DATA_COUNT data file(s)"
fi

# Create transfer script
cat > "$EXPORT_DIR/transfer-to-pi.sh" << 'EOF'
#!/bin/bash
# Transfer exported data to Raspberry Pi
# Usage: ./transfer-to-pi.sh pi-username pi-ip-address

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <pi-username> <pi-ip-address>"
    echo "Example: $0 pi 192.168.1.100"
    exit 1
fi

PI_USER="$1"
PI_HOST="$2"
EXPORT_DIR="$(dirname "$0")"

echo "Transferring data to $PI_USER@$PI_HOST..."

# Create Pi config directory
ssh "$PI_USER@$PI_HOST" "mkdir -p ~/.eero-dashboard"

# Transfer all files
scp "$EXPORT_DIR"/*.json "$PI_USER@$PI_HOST:~/.eero-dashboard/" 2>/dev/null || true
scp "$EXPORT_DIR"/.eero_token* "$PI_USER@$PI_HOST:~/.eero-dashboard/" 2>/dev/null || true
scp "$EXPORT_DIR"/*.log "$PI_USER@$PI_HOST:~/.eero-dashboard/" 2>/dev/null || true

echo "Transfer complete! Now run on Pi:"
echo "sudo systemctl restart eero-dashboard"
EOF

chmod +x "$EXPORT_DIR/transfer-to-pi.sh"
print_success "✅ Created transfer script"

# Create archive
print_status "Creating archive..."
cd "$HOME/Desktop"
tar -czf "eero-dashboard-export.tar.gz" "eero-dashboard-export"
print_success "✅ Created eero-dashboard-export.tar.gz"

echo
echo "📦 Export Summary:"
echo "================================"
echo "Export Directory: $EXPORT_DIR"
echo "Archive: $HOME/Desktop/eero-dashboard-export.tar.gz"
echo
echo "📋 Files Exported:"
ls -la "$EXPORT_DIR"
echo
echo "🚀 Next Steps:"
echo "1. Copy the export directory or archive to your Pi"
echo "2. Run the migration script on the Pi:"
echo "   curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/migrate-from-mac.sh | bash"
echo
echo "Or use the simple transfer script:"
echo "   cd $EXPORT_DIR"
echo "   ./transfer-to-pi.sh pi 192.168.1.100"
echo
print_success "Export complete!"