#!/bin/bash

# Fix HTTPS Webservice Script for Eero Dashboard
# This script will set up a working HTTPS configuration using Nginx as SSL proxy

set -e

echo "🔒 Fixing HTTPS Webservice for Eero Dashboard"
echo "============================================="

# Check if running as correct user
if [ "$USER" != "wifi" ]; then
    echo "⚠️  This script should be run as the 'wifi' user"
    echo "💡 Switch to wifi user: sudo su - wifi"
    exit 1
fi

# Configuration
DASHBOARD_DIR="/home/wifi/eero-dashboard"
SSL_DIR="$DASHBOARD_DIR/ssl"
CERT_FILE="$SSL_DIR/dashboard.crt"
KEY_FILE="$SSL_DIR/dashboard.key"
BACKUP_DIR="$DASHBOARD_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create directories
mkdir -p "$SSL_DIR" "$BACKUP_DIR"

echo "📋 Step 1: Stopping conflicting services..."
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop eero-dashboard 2>/dev/null || true

echo "📋 Step 2: Installing required packages..."
sudo apt update -qq
sudo apt install -y nginx openssl

echo "📋 Step 3: Creating SSL certificates..."
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "🔐 Generating self-signed SSL certificate..."
    sudo openssl req -x509 -newkey rsa:2048 -keyout "$KEY_FILE" -out "$CERT_FILE" \
        -days 365 -nodes -subj "/C=US/ST=State/L=City/O=EeroDashboard/CN=eero-dashboard" \
        2>/dev/null
    
    # Fix permissions
    sudo chown wifi:wifi "$CERT_FILE" "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    chmod 644 "$CERT_FILE"
    echo "✅ SSL certificates created"
else
    echo "✅ SSL certificates already exist"
fi

echo "📋 Step 4: Configuring dashboard for HTTP backend..."
# Reset dashboard to run on HTTP port 80 (backend only)
cd "$DASHBOARD_DIR"

# Remove any SSL config from dashboard
rm -f ssl_config.json

# Reset network binding to defaults
python3 -c "
import json
import os

config_file = '/home/wifi/.eero-dashboard/config.json'
try:
    with open(config_file, 'r') as f:
        config = json.load(f)
except:
    config = {}

# Remove any custom network binding that might cause issues
if 'network_binding' in config:
    del config['network_binding']
if 'port' in config:
    del config['port']
if 'host' in config:
    del config['host']

# Ensure directory exists
os.makedirs(os.path.dirname(config_file), exist_ok=True)
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print('Dashboard config reset to defaults')
"

echo "📋 Step 5: Configuring systemd service..."
# Ensure dashboard service is configured correctly
sudo tee /etc/systemd/system/eero-dashboard.service > /dev/null << 'EOF'
[Unit]
Description=Eero Network Dashboard
After=network.target

[Service]
Type=simple
User=wifi
WorkingDirectory=/home/wifi/eero-dashboard
ExecStart=/home/wifi/eero-dashboard/venv/bin/python /home/wifi/eero-dashboard/dashboard.py
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable eero-dashboard

echo "📋 Step 6: Configuring Nginx SSL proxy..."
# Configure Nginx to handle HTTPS and proxy to dashboard HTTP
sudo tee /etc/nginx/sites-available/eero-dashboard-https > /dev/null << EOF
# HTTP redirect to HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name _;
    
    # SSL Configuration
    ssl_certificate $CERT_FILE;
    ssl_certificate_key $KEY_FILE;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!SRP:!CAMELLIA;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    # Proxy to dashboard
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Port 443;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Remove default nginx site and enable our site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/eero-dashboard-https /etc/nginx/sites-enabled/

echo "📋 Step 7: Updating dashboard to run on port 8080..."
# Modify dashboard to run on port 8080 (so nginx can use 80/443)
cat > "$DASHBOARD_DIR/port_config.py" << 'EOF'
# Port configuration for HTTPS setup
import sys
import os

# Add this to the dashboard startup to force port 8080
def configure_port():
    # This will be imported by dashboard.py
    return {
        'host': '127.0.0.1',
        'port': 8080,
        'debug': False,
        'threaded': True,
        'use_reloader': False
    }
EOF

# Create a wrapper script to ensure port 8080
cat > "$DASHBOARD_DIR/start_dashboard.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/wifi/eero-dashboard')

# Import the original dashboard
import dashboard

# Override the main execution
if __name__ == '__main__':
    print("🚀 Starting Eero Dashboard on port 8080 (HTTPS proxy mode)")
    print("📁 Config directory:", dashboard.LOCAL_DIR)
    print("🔒 HTTPS available via Nginx proxy")
    print("🔧 Press Ctrl+C to stop")
    print("")
    
    # Create default config if needed
    dashboard.create_default_config()
    
    # Initial cache update
    try:
        dashboard.update_cache()
        dashboard.logging.info("Initial cache update complete")
    except Exception as e:
        dashboard.logging.warning("Initial cache update failed: " + str(e))
    
    # Start Flask app on port 8080
    try:
        dashboard.logging.info("Starting Eero Dashboard for HTTPS proxy")
        dashboard.app.run(
            host='127.0.0.1',  # Only listen on localhost
            port=8080,          # Use port 8080
            debug=False,
            threaded=True,
            use_reloader=False
        )
    except KeyboardInterrupt:
        dashboard.logging.info("Dashboard stopped by user")
        print("\n🛑 Dashboard stopped")
    except Exception as e:
        dashboard.logging.error(f"Failed to start dashboard: {e}")
        print(f"\n❌ Error: {e}")
        sys.exit(1)
EOF

chmod +x "$DASHBOARD_DIR/start_dashboard.py"

# Update systemd service to use the wrapper
sudo tee /etc/systemd/system/eero-dashboard.service > /dev/null << EOF
[Unit]
Description=Eero Network Dashboard (HTTPS)
After=network.target

[Service]
Type=simple
User=wifi
WorkingDirectory=$DASHBOARD_DIR
ExecStart=/home/wifi/eero-dashboard/venv/bin/python /home/wifi/eero-dashboard/start_dashboard.py
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

echo "📋 Step 8: Testing Nginx configuration..."
sudo nginx -t

echo "📋 Step 9: Starting services..."
# Start dashboard first
sudo systemctl start eero-dashboard
sleep 3

# Start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "📋 Step 10: Waiting for services to start..."
sleep 5

echo "📋 Step 11: Testing configuration..."
PI_IP=$(hostname -I | awk '{print $1}')

# Test backend (dashboard on port 8080)
echo "🧪 Testing dashboard backend on port 8080..."
if curl -s -I http://127.0.0.1:8080/health > /dev/null; then
    echo "✅ Dashboard backend is responding on port 8080"
else
    echo "❌ Dashboard backend not responding on port 8080"
    echo "🔍 Checking dashboard logs..."
    sudo journalctl -u eero-dashboard --no-pager -l --lines=10
fi

# Test HTTPS frontend
echo "🧪 Testing HTTPS frontend..."
if curl -s -I -k https://$PI_IP/health > /dev/null; then
    echo "✅ HTTPS frontend is working"
else
    echo "❌ HTTPS frontend not working"
    echo "🔍 Checking nginx logs..."
    sudo tail -n 10 /var/log/nginx/error.log
fi

# Test HTTP redirect
echo "🧪 Testing HTTP to HTTPS redirect..."
if curl -s -I http://$PI_IP/health | grep -q "301\|302"; then
    echo "✅ HTTP redirects to HTTPS"
else
    echo "⚠️  HTTP redirect may not be working"
fi

echo ""
echo "🎉 HTTPS Setup Complete!"
echo "======================="
echo ""
echo "📋 Service Status:"
sudo systemctl is-active eero-dashboard && echo "✅ Dashboard: Running" || echo "❌ Dashboard: Not running"
sudo systemctl is-active nginx && echo "✅ Nginx: Running" || echo "❌ Nginx: Not running"

echo ""
echo "🌐 Access URLs:"
echo "   HTTPS: https://$PI_IP"
echo "   HTTP:  http://$PI_IP (redirects to HTTPS)"
echo ""
echo "🎤 Voice API Endpoints (HTTPS):"
echo "   https://$PI_IP/api/voice/status"
echo "   https://$PI_IP/api/voice/devices"
echo "   https://$PI_IP/api/voice/aps"
echo "   https://$PI_IP/api/voice/events"
echo ""
echo "🔧 Service Management:"
echo "   Restart dashboard: sudo systemctl restart eero-dashboard"
echo "   Restart nginx:     sudo systemctl restart nginx"
echo "   View logs:         sudo journalctl -u eero-dashboard -f"
echo "   Nginx logs:        sudo tail -f /var/log/nginx/error.log"
echo ""
echo "⚠️  Note: Self-signed certificate will show browser warnings"
echo "💡 Add security exception in browser to access dashboard"
echo ""
echo "🎯 For Echo integration, use:"
echo "   PI_DASHBOARD_IP=$PI_IP"
echo "   PI_DASHBOARD_PORT=443"
echo "   PI_USE_HTTPS=true"
echo ""
echo "✅ Setup complete! Your dashboard is now running with HTTPS!"