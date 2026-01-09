#!/bin/bash

# Network Interface Binding Configuration Script
# Configure dashboard to bind to specific network interfaces

set -e

echo "🌐 Network Interface Binding Configuration"
echo "========================================="

# Check if running as correct user
if [ "$USER" != "wifi" ]; then
    echo "⚠️  This script should be run as the 'wifi' user"
    echo "💡 Switch to wifi user: sudo su - wifi"
    exit 1
fi

CONFIG_FILE="/home/wifi/.eero-dashboard/config.json"

# Get available network interfaces
echo "📡 Available network interfaces:"
echo ""

interfaces=()
counter=1

# Get wireless interfaces
for iface in $(ls /sys/class/net/ | grep -E '^(wlan|wlp)'); do
    ip_addr=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | head -1)
    if [ -n "$ip_addr" ]; then
        echo "$counter) $iface (Wireless) - $ip_addr"
        interfaces+=("$iface:wireless:$ip_addr")
        ((counter++))
    fi
done

# Get wired interfaces
for iface in $(ls /sys/class/net/ | grep -E '^(eth|enp)'); do
    ip_addr=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | head -1)
    if [ -n "$ip_addr" ]; then
        echo "$counter) $iface (Wired) - $ip_addr"
        interfaces+=("$iface:wired:$ip_addr")
        ((counter++))
    fi
done

echo "$counter) All interfaces (0.0.0.0)"
interfaces+=("all:all:0.0.0.0")
((counter++))

echo ""
read -p "Select interface to bind dashboard to (1-$((counter-1))): " choice

if [ "$choice" -lt 1 ] || [ "$choice" -gt $((counter-1)) ]; then
    echo "❌ Invalid choice"
    exit 1
fi

selected_interface=${interfaces[$((choice-1))]}
IFS=':' read -r iface_name iface_type ip_addr <<< "$selected_interface"

echo ""
echo "🔧 Selected: $iface_name ($iface_type) - $ip_addr"

# Update configuration
if [ -f "$CONFIG_FILE" ]; then
    # Load existing config
    config_content=$(cat "$CONFIG_FILE")
else
    # Create basic config
    config_content='{}'
fi

# Update network binding configuration
updated_config=$(echo "$config_content" | python3 -c "
import sys, json
config = json.load(sys.stdin)
config['network_binding'] = {
    'bind_interface': '$iface_type' if '$iface_type' != 'all' else 'all',
    'bind_address': '$ip_addr'
}
print(json.dumps(config, indent=2))
")

echo "$updated_config" > "$CONFIG_FILE"

echo "✅ Network binding configuration updated"
echo ""
echo "📋 Configuration:"
echo "   Interface: $iface_name ($iface_type)"
echo "   IP Address: $ip_addr"
echo ""
echo "🔄 Restart dashboard to apply changes:"
echo "   sudo systemctl restart eero-dashboard"
echo ""

# Ask if user wants to restart now
read -p "Restart dashboard now? (y/N): " restart_choice
if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
    echo "🔄 Restarting dashboard..."
    sudo systemctl restart eero-dashboard
    sleep 3
    
    if sudo systemctl is-active --quiet eero-dashboard; then
        echo "✅ Dashboard restarted successfully"
        echo "🌐 Access dashboard at: http://$ip_addr"
    else
        echo "❌ Dashboard failed to start. Check logs:"
        echo "   sudo journalctl -u eero-dashboard -f"
    fi
fi