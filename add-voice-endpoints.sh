#!/bin/bash

# Add Voice API Endpoints to Raspberry Pi Dashboard for Echo Integration
# Run this script on your Raspberry Pi to add voice endpoints for Alexa

set -e

echo "🎤 Adding Voice API Endpoints for Echo Integration"
echo "================================================="

# Configuration
DASHBOARD_FILE="/home/wifi/eero-dashboard/dashboard.py"
BACKUP_DIR="/home/wifi/eero-dashboard/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/dashboard.py.backup.$TIMESTAMP"

# Check if running as correct user
if [ "$USER" != "wifi" ]; then
    echo "⚠️  This script should be run as the 'wifi' user"
    echo "💡 Switch to wifi user: sudo su - wifi"
    echo "💡 Then run: curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/add-voice-endpoints.sh | bash"
    exit 1
fi

# Check if dashboard file exists
if [ ! -f "$DASHBOARD_FILE" ]; then
    echo "❌ Dashboard file not found: $DASHBOARD_FILE"
    echo "💡 Make sure the Eero Dashboard is installed and running"
    exit 1
fi

# Check if voice endpoints already exist
if grep -q "/api/voice/status" "$DASHBOARD_FILE"; then
    echo "✅ Voice endpoints already exist in dashboard"
    echo "🎤 Your dashboard is ready for Echo integration!"
    echo ""
    echo "📋 Available voice endpoints:"
    echo "   - http://$(hostname -I | awk '{print $1}')/api/voice/status"
    echo "   - http://$(hostname -I | awk '{print $1}')/api/voice/devices"
    echo "   - http://$(hostname -I | awk '{print $1}')/api/voice/aps"
    echo "   - http://$(hostname -I | awk '{print $1}')/api/voice/events"
    exit 0
fi

echo "🔧 Adding voice endpoints to dashboard..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup
echo "📋 Creating backup: $BACKUP_FILE"
cp "$DASHBOARD_FILE" "$BACKUP_FILE"

# Create the voice endpoints code
cat > /tmp/voice_endpoints.py << 'EOF'

# Voice API endpoints for Echo integration
@app.route('/api/voice/status')
def get_voice_status():
    """Get network status optimized for voice responses"""
    try:
        update_cache()
        combined_data = data_cache['combined']
        
        total_devices = combined_data.get('total_devices', 0)
        wireless_devices = combined_data.get('wireless_devices', 0)
        wired_devices = combined_data.get('wired_devices', 0)
        
        # Calculate AP statistics
        total_aps = 0
        online_aps = 0
        busiest_ap = None
        max_devices = 0
        
        for network_id, network_data in data_cache.get('networks', {}).items():
            ap_data = network_data.get('ap_data', {})
            for ap_id, ap_info in ap_data.items():
                total_aps += 1
                online_aps += 1  # All APs in data are considered online
                
                if ap_info.get('total_devices', 0) > max_devices:
                    max_devices = ap_info.get('total_devices', 0)
                    busiest_ap = {
                        'name': ap_info.get('name', 'Unknown AP'),
                        'device_count': max_devices
                    }
        
        return jsonify({
            'total_devices': total_devices,
            'wireless_devices': wireless_devices,
            'wired_devices': wired_devices,
            'total_aps': total_aps,
            'online_aps': online_aps,
            'busiest_ap': busiest_ap,
            'internet_status': 'connected',  # Assume connected if we have data
            'last_update': combined_data.get('last_update')
        })
        
    except Exception as e:
        logging.error(f"Voice status error: {str(e)}")
        return jsonify({
            'total_devices': 0,
            'wireless_devices': 0,
            'wired_devices': 0,
            'total_aps': 0,
            'online_aps': 0,
            'busiest_ap': None,
            'internet_status': 'unknown',
            'last_update': None
        }), 500

@app.route('/api/voice/devices')
def get_voice_devices():
    """Get device information optimized for voice responses"""
    try:
        update_cache()
        combined_data = data_cache['combined']
        
        total_devices = combined_data.get('total_devices', 0)
        wireless_devices = combined_data.get('wireless_devices', 0)
        wired_devices = combined_data.get('wired_devices', 0)
        device_os = combined_data.get('device_os', {})
        
        # Find busiest AP
        busiest_ap = None
        max_devices = 0
        
        for network_id, network_data in data_cache.get('networks', {}).items():
            ap_data = network_data.get('ap_data', {})
            for ap_id, ap_info in ap_data.items():
                if ap_info.get('total_devices', 0) > max_devices:
                    max_devices = ap_info.get('total_devices', 0)
                    busiest_ap = {
                        'name': ap_info.get('name', 'Unknown AP'),
                        'device_count': max_devices
                    }
        
        return jsonify({
            'total_devices': total_devices,
            'wireless_devices': wireless_devices,
            'wired_devices': wired_devices,
            'device_types': device_os,
            'busiest_ap': busiest_ap,
            'last_update': combined_data.get('last_update')
        })
        
    except Exception as e:
        logging.error(f"Voice devices error: {str(e)}")
        return jsonify({
            'total_devices': 0,
            'wireless_devices': 0,
            'wired_devices': 0,
            'device_types': {},
            'busiest_ap': None,
            'last_update': None
        }), 500

@app.route('/api/voice/aps')
def get_voice_aps():
    """Get access point information optimized for voice responses"""
    try:
        update_cache()
        
        total_aps = 0
        busiest_ap = None
        max_devices = 0
        
        for network_id, network_data in data_cache.get('networks', {}).items():
            ap_data = network_data.get('ap_data', {})
            for ap_id, ap_info in ap_data.items():
                total_aps += 1
                
                if ap_info.get('total_devices', 0) > max_devices:
                    max_devices = ap_info.get('total_devices', 0)
                    busiest_ap = {
                        'name': ap_info.get('name', 'Unknown AP'),
                        'device_count': max_devices,
                        'model': ap_info.get('model', 'Unknown')
                    }
        
        return jsonify({
            'total_aps': total_aps,
            'online_aps': total_aps,  # All APs in data are considered online
            'busiest_ap': busiest_ap,
            'last_update': data_cache['combined'].get('last_update')
        })
        
    except Exception as e:
        logging.error(f"Voice APs error: {str(e)}")
        return jsonify({
            'total_aps': 0,
            'online_aps': 0,
            'busiest_ap': None,
            'last_update': None
        }), 500

@app.route('/api/voice/events')
def get_voice_events():
    """Get recent network events optimized for voice responses"""
    try:
        # For now, return mock events since we don't have real event tracking
        # This can be enhanced later with actual event monitoring
        current_time = get_timezone_aware_now()
        
        # Generate some sample events based on current device data
        events = []
        combined_data = data_cache['combined']
        devices = combined_data.get('devices', [])
        
        # Create mock recent events for voice responses
        if devices:
            # Take first few devices as "recently connected"
            for i, device in enumerate(devices[:3]):
                event_time = current_time - timedelta(minutes=i*15)
                events.append({
                    'type': 'device_connected',
                    'device_name': device.get('name', 'Unknown Device'),
                    'timestamp': event_time.isoformat(),
                    'description': f"{device.get('name', 'Unknown Device')} connected"
                })
        
        return jsonify({
            'events': events,
            'event_count': len(events),
            'last_update': combined_data.get('last_update')
        })
        
    except Exception as e:
        logging.error(f"Voice events error: {str(e)}")
        return jsonify({
            'events': [],
            'event_count': 0,
            'last_update': None
        }), 500

EOF

# Find the insertion point (before the main execution block)
LINE_NUM=$(grep -n "if __name__ == '__main__':" "$DASHBOARD_FILE" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "❌ Could not find insertion point in dashboard.py"
    echo "💡 The dashboard file may have been modified"
    exit 1
fi

echo "🔧 Inserting voice endpoints at line $LINE_NUM"

# Insert the voice endpoints before the main block
head -n $((LINE_NUM - 1)) "$DASHBOARD_FILE" > /tmp/dashboard_new.py
cat /tmp/voice_endpoints.py >> /tmp/dashboard_new.py
tail -n +$LINE_NUM "$DASHBOARD_FILE" >> /tmp/dashboard_new.py

# Replace the original file
mv /tmp/dashboard_new.py "$DASHBOARD_FILE"

# Clean up
rm -f /tmp/voice_endpoints.py

echo "✅ Voice endpoints added successfully"

# Restart the dashboard service
echo "🔄 Restarting dashboard service..."
sudo systemctl restart eero-dashboard

# Wait a moment for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet eero-dashboard; then
    echo "✅ Dashboard service restarted successfully"
else
    echo "⚠️  Dashboard service may have issues. Checking status..."
    sudo systemctl status eero-dashboard --no-pager -l
fi

echo ""
echo "🎉 Voice API endpoints successfully added!"
echo ""
echo "📋 Available endpoints:"
PI_IP=$(hostname -I | awk '{print $1}')
echo "   - http://$PI_IP/api/voice/status"
echo "   - http://$PI_IP/api/voice/devices"
echo "   - http://$PI_IP/api/voice/aps"
echo "   - http://$PI_IP/api/voice/events"
echo ""
echo "🧪 Test an endpoint:"
echo "   curl http://$PI_IP/api/voice/status"
echo ""
echo "📱 Next steps:"
echo "1. 🏠 Note your Pi IP address: $PI_IP"
echo "2. 🎤 Set up your Echo skill with this IP"
echo "3. 🗣️  Try: 'Alexa, ask Eero Dashboard how many devices are connected'"
echo ""
echo "✅ Setup complete! Your Pi is ready for Echo integration."