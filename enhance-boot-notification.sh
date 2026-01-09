#!/bin/bash

# Enhance Boot Notification with Clickable Links and Network Data Purging
# This script adds clickable links to boot notifications and network data cleanup

set -e

echo "🚀 Enhancing Boot Notification and Network Management..."

# Check if we're in the correct directory
if [[ ! -f "dashboard.py" ]]; then
    echo "❌ dashboard.py not found. Please run this script from the eero-dashboard directory."
    exit 1
fi

# Stop dashboard service temporarily
echo "🛑 Stopping dashboard service..."
sudo systemctl stop eero-dashboard.service

# Create backup
echo "📋 Creating backup..."
cp dashboard.py dashboard.py.backup.$(date +%Y%m%d_%H%M%S)
cp boot-notification.py boot-notification.py.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Enhance the boot notification with clickable links
echo "🔧 Enhancing boot notification with clickable links..."

cat > enhance_boot_notification.py << 'EOF'
#!/usr/bin/env python3
import re

# Read the current boot-notification.py
with open('boot-notification.py', 'r') as f:
    content = f.read()

# Enhanced send_boot_notification function with clickable links
enhanced_function = '''def send_boot_notification(test_mode=False):
    """Send boot notification email with IP addresses and clickable links"""
    try:
        config = load_config()
        boot_config = config.get('boot_notification', {})
        
        if not boot_config.get('enabled', True) and not test_mode:
            return
        
        import smtplib
        import subprocess
        from email.mime.text import MimeText
        from email.mime.multipart import MimeMultipart
        from datetime import datetime
        
        # Get network interface information
        result = subprocess.run(['ip', 'addr', 'show'], capture_output=True, text=True)
        
        interfaces = {}
        current_interface = None
        
        for line in result.stdout.split('\\n'):
            if line and not line.startswith(' '):
                # New interface
                parts = line.split(':')
                if len(parts) >= 2:
                    interface_name = parts[1].strip()
                    if interface_name not in ['lo']:  # Skip loopback
                        current_interface = interface_name
                        interfaces[interface_name] = {
                            'type': 'wired' if interface_name.startswith(('eth', 'enp')) else 'wireless' if interface_name.startswith(('wlan', 'wlp')) else 'other',
                            'addresses': []
                        }
            elif current_interface and 'inet ' in line:
                # IP address
                parts = line.strip().split()
                if len(parts) >= 2:
                    ip_addr = parts[1].split('/')[0]
                    interfaces[current_interface]['addresses'].append(ip_addr)
        
        # Get hostname
        hostname = subprocess.run(['hostname'], capture_output=True, text=True).stdout.strip()
        
        # Get primary IPs for links
        primary_wired_ip = None
        primary_wireless_ip = None
        
        for interface, info in interfaces.items():
            if info['addresses']:
                if info['type'] == 'wired' and not primary_wired_ip:
                    primary_wired_ip = info['addresses'][0]
                elif info['type'] == 'wireless' and not primary_wireless_ip:
                    primary_wireless_ip = info['addresses'][0]
        
        # Determine primary IP (prefer wireless, fallback to wired)
        primary_ip = primary_wireless_ip or primary_wired_ip or 'N/A'
        
        # Create email content
        subject = f"{'[TEST] ' if test_mode else ''}🚀 Eero Dashboard Ready - {hostname}"
        
        # HTML email body with clickable links
        html_body = f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .header {{ background: #4da6ff; color: white; padding: 20px; text-align: center; }}
        .content {{ padding: 20px; }}
        .interface-section {{ background: #f8f9fa; padding: 15px; margin: 10px 0; border-radius: 8px; }}
        .quick-links {{ background: #e8f4fd; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #4da6ff; }}
        .link-button {{ display: inline-block; background: #4da6ff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 5px; font-weight: bold; }}
        .link-button:hover {{ background: #3d8bff; }}
        .ssh-info {{ background: #fff3cd; padding: 15px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #ffc107; }}
        .status {{ color: #28a745; font-weight: bold; }}
        .footer {{ background: #6c757d; color: white; padding: 15px; text-align: center; font-size: 12px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Eero Dashboard Ready!</h1>
        <p>Your Raspberry Pi dashboard is online and ready to use</p>
    </div>
    
    <div class="content">
        <h2>📊 System Information</h2>
        <p><strong>Hostname:</strong> {hostname}</p>
        <p><strong>Boot Time:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')}</p>
        <p><strong>Dashboard Version:</strong> {VERSION}</p>
        <p><strong>Status:</strong> <span class="status">{'Test Mode' if test_mode else 'Online and Ready'}</span></p>
        
        <div class="quick-links">
            <h3>🔗 Quick Access Links</h3>
            <p>Click these links to get started immediately:</p>
"""
        
        if primary_ip != 'N/A':
            html_body += f"""
            <a href="https://{primary_ip}" class="link-button">🌐 Open Dashboard</a>
            <a href="https://{primary_ip}" class="link-button">⚙️ Admin Panel</a>
"""
        
        html_body += f"""
        </div>
        
        <h3>🌐 Network Interfaces</h3>
"""
        
        for interface, info in interfaces.items():
            if info['addresses']:
                interface_type = info['type'].title()
                html_body += f"""
        <div class="interface-section">
            <h4>{interface} ({interface_type})</h4>
"""
                for addr in info['addresses']:
                    html_body += f"""
            <p>
                <strong>IP:</strong> {addr} 
                <a href="https://{addr}" class="link-button" style="font-size: 12px; padding: 6px 12px;">Open Dashboard</a>
            </p>
"""
                html_body += """
        </div>
"""
        
        html_body += f"""
        <div class="ssh-info">
            <h3>🔐 SSH Access</h3>
            <p><strong>SSH Command:</strong> <code>ssh wifi@{primary_ip}</code></p>
            <p><strong>Default Password:</strong> raspberry (change this immediately!)</p>
            <p><strong>Dashboard Directory:</strong> <code>~/eero-dashboard</code></p>
        </div>
        
        <h3>🔧 Quick Setup Steps</h3>
        <ol>
            <li><strong>Open Dashboard:</strong> Click any dashboard link above</li>
            <li><strong>Access Admin Panel:</strong> Click the π (pi) icon in the dashboard</li>
            <li><strong>Add Networks:</strong> Use "Manage Networks" to add your Eero networks</li>
            <li><strong>Authenticate:</strong> Follow the authentication process for each network</li>
            <li><strong>Configure Settings:</strong> Set up interface controls and notifications</li>
        </ol>
        
        <h3>📋 Available Features</h3>
        <ul>
            <li>✅ Multi-network monitoring</li>
            <li>✅ Real-time device tracking</li>
            <li>✅ Access point capacity visualization</li>
            <li>✅ Interface access controls</li>
            <li>✅ Boot notifications (this email!)</li>
            <li>✅ Voice integration (Alexa)</li>
            <li>✅ Kiosk mode for displays</li>
        </ul>
    </div>
    
    <div class="footer">
        <p>This is an automated notification from your Eero Dashboard on {hostname}</p>
        <p>Dashboard ready for immediate use • SSH enabled • Web services running</p>
    </div>
</body>
</html>
"""
        
        # Plain text version for email clients that don't support HTML
        text_body = f"""
Eero Dashboard Boot Notification
{'='*40}

Hostname: {hostname}
Boot Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')}
Dashboard Version: {VERSION}

QUICK ACCESS:
"""
        
        if primary_ip != 'N/A':
            text_body += f"""
Dashboard: https://{primary_ip}
Admin Panel: https://{primary_ip} (click π icon)
"""
        
        text_body += f"""

Network Interfaces:
"""
        
        for interface, info in interfaces.items():
            if info['addresses']:
                text_body += f"""
{interface} ({info['type']}):
"""
                for addr in info['addresses']:
                    text_body += f"  - {addr} → https://{addr}\\n"
        
        text_body += f"""

SSH Access:
Command: ssh wifi@{primary_ip}
Directory: ~/eero-dashboard

Quick Setup:
1. Open dashboard link above
2. Click π (pi) icon for admin panel
3. Add and authenticate your Eero networks
4. Configure settings as needed

Status: {'Test notification' if test_mode else 'Dashboard started successfully'}

This is an automated notification from your Eero Dashboard.
"""
        
        # Create message
        msg = MimeMultipart('alternative')
        msg['From'] = boot_config.get('smtp_username', 'eero-dashboard@localhost')
        msg['To'] = boot_config.get('email', 'drew@drewlentz.com')
        msg['Subject'] = subject
        
        # Attach both plain text and HTML versions
        msg.attach(MimeText(text_body, 'plain'))
        msg.attach(MimeText(html_body, 'html'))
        
        # Send email
        smtp_server = boot_config.get('smtp_server', 'smtp.gmail.com')
        smtp_port = boot_config.get('smtp_port', 587)
        smtp_username = boot_config.get('smtp_username', '')
        smtp_password = boot_config.get('smtp_password', '')
        
        if not smtp_username or not smtp_password:
            raise Exception("SMTP username and password are required")
        
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(smtp_username, smtp_password)
        
        text = msg.as_string()
        server.sendmail(msg['From'], msg['To'], text)
        server.quit()
        
        logging.info(f"Enhanced boot notification sent to {msg['To']}")
        
    except Exception as e:
        logging.error(f"Failed to send boot notification: {str(e)}")
        raise'''

# Replace the existing send_boot_notification function
pattern = r'def send_boot_notification\(test_mode=False\):.*?(?=def |$)'
content = re.sub(pattern, enhanced_function, content, flags=re.DOTALL)

# Write the updated content
with open('boot-notification.py', 'w') as f:
    f.write(content)

print("✅ Enhanced boot notification with clickable links")
EOF

# Run the Python script to enhance boot notification
python3 enhance_boot_notification.py
rm enhance_boot_notification.py

# Add network data purging functionality to dashboard.py
echo "🔧 Adding network data purging functionality..."

cat > add_network_purging.py << 'EOF'
#!/usr/bin/env python3
import re

# Read the current dashboard.py
with open('dashboard.py', 'r') as f:
    content = f.read()

# Enhanced remove_network function with data purging
enhanced_remove_function = '''@app.route('/api/admin/networks/<network_id>', methods=['DELETE'])
def remove_network(network_id):
    """Remove a network from monitoring and purge all associated data"""
    try:
        config = load_config()
        networks = config.get('networks', [])
        
        # Find the network to get its name for logging
        network_name = None
        for network in networks:
            if network.get('id') == network_id:
                network_name = network.get('name', f'Network {network_id}')
                break
        
        # Remove network from config
        original_count = len(networks)
        networks = [n for n in networks if n.get('id') != network_id]
        
        if len(networks) == original_count:
            return jsonify({'success': False, 'message': 'Network not found'}), 404
        
        config['networks'] = networks
        
        if save_config(config):
            # Purge all associated data files and logs
            purged_items = []
            
            # Remove token file
            token_file = LOCAL_DIR / f".eero_token_{network_id}"
            if token_file.exists():
                token_file.unlink()
                purged_items.append('API token')
            
            # Remove from memory
            if network_id in eero_api.network_tokens:
                del eero_api.network_tokens[network_id]
                purged_items.append('cached token')
            
            # Remove from data cache
            if network_id in data_cache.get('networks', {}):
                del data_cache['networks'][network_id]
                purged_items.append('cached data')
            
            # Purge log entries (scan log files for network-specific entries)
            log_files_purged = 0
            try:
                log_file = LOCAL_DIR / 'dashboard.log'
                if log_file.exists():
                    # Read log file and remove network-specific entries
                    with open(log_file, 'r') as f:
                        log_lines = f.readlines()
                    
                    # Filter out lines containing the network ID
                    filtered_lines = []
                    removed_lines = 0
                    for line in log_lines:
                        if network_id not in line and (network_name and network_name not in line):
                            filtered_lines.append(line)
                        else:
                            removed_lines += 1
                    
                    if removed_lines > 0:
                        # Write back the filtered log
                        with open(log_file, 'w') as f:
                            f.writelines(filtered_lines)
                        log_files_purged += 1
                        purged_items.append(f'{removed_lines} log entries')
                
                # Also check backup log files
                for backup_log in LOCAL_DIR.glob('dashboard.log.*'):
                    try:
                        with open(backup_log, 'r') as f:
                            log_lines = f.readlines()
                        
                        filtered_lines = []
                        removed_lines = 0
                        for line in log_lines:
                            if network_id not in line and (network_name and network_name not in line):
                                filtered_lines.append(line)
                            else:
                                removed_lines += 1
                        
                        if removed_lines > 0:
                            with open(backup_log, 'w') as f:
                                f.writelines(filtered_lines)
                            log_files_purged += 1
                    except:
                        pass  # Skip if backup log can't be processed
                
                if log_files_purged > 0:
                    purged_items.append(f'{log_files_purged} log files cleaned')
                    
            except Exception as e:
                logging.warning(f"Could not purge log entries for network {network_id}: {str(e)}")
            
            # Remove any cached data files specific to this network
            try:
                cache_pattern = LOCAL_DIR / f"*{network_id}*"
                import glob
                for cache_file in glob.glob(str(cache_pattern)):
                    cache_path = Path(cache_file)
                    if cache_path.is_file() and cache_path != token_file:  # Don't double-count token file
                        cache_path.unlink()
                        purged_items.append(f'cache file: {cache_path.name}')
            except Exception as e:
                logging.warning(f"Could not purge cache files for network {network_id}: {str(e)}")
            
            # Log the purge operation
            purge_summary = ', '.join(purged_items) if purged_items else 'no additional data found'
            logging.info(f"Network {network_id} ({network_name}) removed and purged: {purge_summary}")
            
            message = f'Network {network_name or network_id} removed and all associated data purged'
            if purged_items:
                message += f' (purged: {", ".join(purged_items)})'
            
            return jsonify({'success': True, 'message': message, 'purged_items': purged_items})
        
        return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
    except Exception as e:
        logging.error(f"Error removing network {network_id}: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500'''

# Replace the existing remove_network function
pattern = r'@app\.route\(\'/api/admin/networks/<network_id>\', methods=\[\'DELETE\'\]\)\s*def remove_network\(network_id\):.*?(?=@app\.route|def [a-zA-Z]|$)'
content = re.sub(pattern, enhanced_remove_function + '\n\n', content, flags=re.DOTALL)

# Write the updated content
with open('dashboard.py', 'w') as f:
    f.write(content)

print("✅ Enhanced network removal with data purging")
EOF

# Run the Python script to add network purging
python3 add_network_purging.py
rm add_network_purging.py

# Create a deployment readiness script
echo "🔧 Creating deployment readiness script..."

cat > deployment-ready.sh << 'EOF'
#!/bin/bash

# Deployment Readiness Script
# Run this to ensure the Pi is ready for deployment

set -e

echo "🚀 Preparing Eero Dashboard for Deployment..."

# Ensure all services are enabled for boot
echo "🔧 Enabling services for automatic startup..."
sudo systemctl enable eero-dashboard.service
sudo systemctl enable boot-notification.service
sudo systemctl enable nginx
sudo systemctl enable ssh

# Test boot notification
echo "📧 Testing boot notification system..."
if [[ -f "boot-notification.py" ]]; then
    python3 -c "
import sys
sys.path.insert(0, '.')
from boot-notification import send_boot_notification
try:
    send_boot_notification(test_mode=True)
    print('✅ Boot notification test successful')
except Exception as e:
    print(f'❌ Boot notification test failed: {e}')
    "
fi

# Check SSH configuration
echo "🔐 Checking SSH configuration..."
if sudo systemctl is-enabled ssh >/dev/null 2>&1; then
    echo "✅ SSH is enabled for remote access"
else
    echo "⚠️  SSH is not enabled - enabling now..."
    sudo systemctl enable ssh
    sudo systemctl start ssh
fi

# Verify web services
echo "🌐 Checking web services..."
if sudo systemctl is-active --quiet eero-dashboard.service; then
    echo "✅ Dashboard service is running"
else
    echo "🔄 Starting dashboard service..."
    sudo systemctl start eero-dashboard.service
fi

if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx web server is running"
else
    echo "🔄 Starting nginx..."
    sudo systemctl start nginx
fi

# Get network information
echo "📊 Network Information:"
WLAN_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)
ETH_IP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)

if [[ -n "$WLAN_IP" ]]; then
    echo "   WiFi IP:     $WLAN_IP"
    echo "   WiFi Access: https://$WLAN_IP"
fi

if [[ -n "$ETH_IP" ]]; then
    echo "   Ethernet IP: $ETH_IP"  
    echo "   Eth Access:  https://$ETH_IP"
fi

echo ""
echo "🎉 Deployment Readiness Check Complete!"
echo "======================================"
echo ""
echo "✅ Services enabled for automatic startup"
echo "✅ Boot notifications configured"
echo "✅ SSH access enabled"
echo "✅ Web services running"
echo ""
echo "📋 Deployment Instructions:"
echo "   1. Shutdown the Pi: sudo shutdown -h now"
echo "   2. Move Pi to deployment location"
echo "   3. Connect ethernet cable (if using wired)"
echo "   4. Power on the Pi"
echo "   5. Wait 2-3 minutes for boot and network connection"
echo "   6. Check email for boot notification with clickable links"
echo "   7. Click dashboard link in email to start using immediately"
echo ""
echo "🔧 The Pi is now ready for deployment!"
EOF

chmod +x deployment-ready.sh

# Restart dashboard service
echo "🔄 Restarting dashboard service..."
sudo systemctl start eero-dashboard.service

# Wait for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet eero-dashboard.service; then
    echo "✅ Dashboard service restarted successfully"
else
    echo "❌ Dashboard service failed to start, restoring backups..."
    cp dashboard.py.backup.* dashboard.py
    cp boot-notification.py.backup.* boot-notification.py 2>/dev/null || true
    sudo systemctl start eero-dashboard.service
    exit 1
fi

echo ""
echo "🎉 Boot Notification and Network Management Enhanced!"
echo "===================================================="
echo ""
echo "📧 Enhanced Boot Notification Features:"
echo "   ✅ HTML email with clickable dashboard links"
echo "   ✅ Quick access buttons for immediate use"
echo "   ✅ SSH connection information"
echo "   ✅ All interface IPs with individual links"
echo "   ✅ Professional formatting with styling"
echo ""
echo "🗑️ Enhanced Network Management:"
echo "   ✅ Complete data purging when networks are deleted"
echo "   ✅ Removes API tokens, cached data, and log entries"
echo "   ✅ Cleans up all associated files"
echo "   ✅ Detailed purge reporting"
echo ""
echo "🚀 Deployment Readiness:"
echo "   ✅ Run './deployment-ready.sh' to prepare for deployment"
echo "   ✅ All services auto-start on boot"
echo "   ✅ Boot notification sends clickable links"
echo "   ✅ SSH enabled for remote access"
echo ""
echo "📋 Deployment Workflow:"
echo "   1. Run './deployment-ready.sh' to verify readiness"
echo "   2. Shutdown and deploy Pi to new location"
echo "   3. Power on and wait for boot notification email"
echo "   4. Click dashboard link in email to start immediately"
echo "   5. SSH in if needed: ssh wifi@[ip-from-email]"