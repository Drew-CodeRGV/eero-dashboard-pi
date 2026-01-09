#!/bin/bash

# Simple Admin Panel Fix - Uses Python for reliable HTML manipulation
# Run this on your Raspberry Pi to fix the admin panel formatting

set -e

echo "🎨 Fixing Pi Admin Panel Layout (Simple Method)..."

# Check if we're in the dashboard directory
if [[ ! -f "dashboard.py" ]]; then
    echo "❌ Please run this script from the eero-dashboard directory"
    echo "   cd ~/eero-dashboard"
    exit 1
fi

# Stop dashboard service temporarily
echo "🛑 Stopping dashboard service..."
sudo systemctl stop eero-dashboard.service

# Create backup
echo "📋 Creating backup..."
cp index.html index.html.backup.$(date +%Y%m%d_%H%M%S)

# Create Python script to fix the admin panel
cat > fix_admin_panel.py << 'EOF'
#!/usr/bin/env python3
import re

# Read the current index.html
with open('index.html', 'r') as f:
    content = f.read()

# Define the new organized admin menu HTML
new_admin_menu = '''            <div class="admin-menu">
                <!-- System Management -->
                <div class="admin-section">
                    <h3 class="admin-section-title"><i class="fas fa-cog"></i> System Management</h3>
                    <button class="admin-btn" onclick="updateDashboard()">
                        <i class="fas fa-sync"></i><span>Check for Updates</span>
                    </button>
                    <button class="admin-btn" onclick="showInterfaceAccessForm()">
                        <i class="fas fa-wifi"></i><span>Interface Access Controls</span>
                    </button>
                    <button class="admin-btn" onclick="showBootNotificationForm()">
                        <i class="fas fa-envelope"></i><span>Boot Notification Settings</span>
                    </button>
                </div>

                <!-- Network Configuration -->
                <div class="admin-section">
                    <h3 class="admin-section-title"><i class="fas fa-network-wired"></i> Network Configuration</h3>
                    <button class="admin-btn" onclick="showNetworksManager()">
                        <i class="fas fa-sitemap"></i><span>Manage Networks</span>
                    </button>
                    <button class="admin-btn" onclick="showNetworkIdForm()">
                        <i class="fas fa-edit"></i><span>Quick Network ID Change</span>
                    </button>
                    <button class="admin-btn" onclick="showReauthorizeForm()">
                        <i class="fas fa-key"></i><span>Legacy Reauthorize</span>
                    </button>
                </div>

                <!-- Display & Interface -->
                <div class="admin-section">
                    <h3 class="admin-section-title"><i class="fas fa-desktop"></i> Display & Interface</h3>
                    <button class="admin-btn" onclick="showKioskSettingsForm()">
                        <i class="fas fa-tv"></i><span>Kiosk Mode Settings</span>
                    </button>
                    <button class="admin-btn" onclick="showTimezoneForm()">
                        <i class="fas fa-clock"></i><span>Change Timezone</span>
                    </button>
                </div>
            </div>'''

# Replace the existing admin menu
pattern = r'<div class="admin-menu">.*?</div>'
content = re.sub(pattern, new_admin_menu, content, flags=re.DOTALL)

# Add CSS for admin sections (insert before </style>)
admin_css = '''
        /* Admin Panel Section Styles */
        .admin-section {
            margin-bottom: 25px;
            padding: 15px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 12px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .admin-section-title {
            margin: 0 0 15px 0;
            padding: 0 0 10px 0;
            font-size: 16px;
            font-weight: 600;
            color: #4da6ff;
            border-bottom: 1px solid rgba(77, 166, 255, 0.3);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .admin-section-title i {
            font-size: 14px;
        }
        
        .admin-section .admin-btn {
            margin-bottom: 8px;
            width: 100%;
        }
        
        .admin-section .admin-btn:last-child {
            margin-bottom: 0;
        }
        
        /* Enhanced Form Styles */
        .admin-form {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 12px;
            padding: 20px;
            margin-top: 20px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .admin-form h3 {
            margin: 0 0 15px 0;
            color: #4da6ff;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #ffffff;
            font-weight: 500;
            font-size: 14px;
        }
        
        .checkbox-label {
            display: flex;
            align-items: center;
            cursor: pointer;
            margin-bottom: 10px;
            font-size: 14px;
            color: #ffffff;
        }
        
        .checkbox-label input[type="checkbox"] {
            margin-right: 10px;
            transform: scale(1.2);
            accent-color: #4da6ff;
        }
        
        .form-actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        
        .form-btn.secondary {
            background: #6c757d;
        }
        
        .form-btn.secondary:hover {
            background: #5a6268;
        }

'''

# Insert CSS before </style>
content = content.replace('</style>', admin_css + '</style>')

# Add JavaScript functions for interface controls and boot notifications
js_functions = '''
        // Interface Access Controls
        async function showInterfaceAccessForm() {
            try {
                const response = await fetch('/api/admin/interface-access');
                const data = await response.json();
                
                if (data.success) {
                    const config = data.interface_access;
                    
                    document.getElementById('adminFormContainer').innerHTML = `
                        <div class="admin-form">
                            <h3><i class="fas fa-wifi"></i> Interface Access Controls</h3>
                            <p>Control which network interfaces can access the dashboard web service.</p>
                            
                            <div class="form-group">
                                <label class="checkbox-label">
                                    <input type="checkbox" id="wiredEnabled" ${config.wired_enabled ? 'checked' : ''}>
                                    <span class="checkmark"></span>
                                    Enable access via wired interface (Ethernet)
                                </label>
                            </div>
                            
                            <div class="form-group">
                                <label class="checkbox-label">
                                    <input type="checkbox" id="wirelessEnabled" ${config.wireless_enabled ? 'checked' : ''}>
                                    <span class="checkmark"></span>
                                    Enable access via wireless interface (WiFi)
                                </label>
                            </div>
                            
                            <div class="form-group">
                                <label class="checkbox-label">
                                    <input type="checkbox" id="allowExternal" ${config.allow_external ? 'checked' : ''}>
                                    <span class="checkmark"></span>
                                    Allow external access (from other networks)
                                </label>
                            </div>
                            
                            <div class="form-actions">
                                <button class="form-btn" onclick="saveInterfaceAccess()">Save Settings</button>
                                <button class="form-btn secondary" onclick="clearAdminForm()">Cancel</button>
                            </div>
                        </div>
                    `;
                } else {
                    showAdminAlert('error', 'Failed to load interface access settings: ' + data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error loading interface access settings: ' + error.message);
            }
        }
        
        async function saveInterfaceAccess() {
            try {
                const wiredEnabled = document.getElementById('wiredEnabled').checked;
                const wirelessEnabled = document.getElementById('wirelessEnabled').checked;
                const allowExternal = document.getElementById('allowExternal').checked;
                
                const response = await fetch('/api/admin/interface-access', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        wired_enabled: wiredEnabled,
                        wireless_enabled: wirelessEnabled,
                        allow_external: allowExternal
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    showAdminAlert('success', data.message);
                    clearAdminForm();
                } else {
                    showAdminAlert('error', data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error saving interface access settings: ' + error.message);
            }
        }
        
        // Boot Notification Settings
        async function showBootNotificationForm() {
            try {
                const response = await fetch('/api/admin/boot-notification');
                const data = await response.json();
                
                if (data.success) {
                    const config = data.boot_notification;
                    
                    document.getElementById('adminFormContainer').innerHTML = `
                        <div class="admin-form">
                            <h3><i class="fas fa-envelope"></i> Boot Notification Settings</h3>
                            <p>Configure email notifications sent when the dashboard starts up.</p>
                            
                            <div class="form-group">
                                <label class="checkbox-label">
                                    <input type="checkbox" id="bootNotificationEnabled" ${config.enabled ? 'checked' : ''}>
                                    <span class="checkmark"></span>
                                    Enable boot notifications
                                </label>
                            </div>
                            
                            <div class="form-group">
                                <label for="notificationEmail">Notification Email:</label>
                                <input type="email" id="notificationEmail" value="${config.email}" placeholder="drew@drewlentz.com">
                            </div>
                            
                            <div class="form-group">
                                <label for="smtpServer">SMTP Server:</label>
                                <input type="text" id="smtpServer" value="${config.smtp_server}" placeholder="smtp.gmail.com">
                            </div>
                            
                            <div class="form-group">
                                <label for="smtpPort">SMTP Port:</label>
                                <input type="number" id="smtpPort" value="${config.smtp_port}" placeholder="587">
                            </div>
                            
                            <div class="form-group">
                                <label for="smtpUsername">SMTP Username:</label>
                                <input type="text" id="smtpUsername" value="${config.smtp_username}" placeholder="your-email@gmail.com">
                            </div>
                            
                            <div class="form-group">
                                <label for="smtpPassword">SMTP Password:</label>
                                <input type="password" id="smtpPassword" value="${config.smtp_password}" placeholder="Enter password">
                                <small>For Gmail, use an App Password instead of your regular password</small>
                            </div>
                            
                            <div class="form-actions">
                                <button class="form-btn" onclick="saveBootNotification()">Save Settings</button>
                                <button class="form-btn secondary" onclick="testBootNotification()">Send Test Email</button>
                                <button class="form-btn secondary" onclick="clearAdminForm()">Cancel</button>
                            </div>
                        </div>
                    `;
                } else {
                    showAdminAlert('error', 'Failed to load boot notification settings: ' + data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error loading boot notification settings: ' + error.message);
            }
        }
        
        async function saveBootNotification() {
            try {
                const enabled = document.getElementById('bootNotificationEnabled').checked;
                const email = document.getElementById('notificationEmail').value.trim();
                const smtpServer = document.getElementById('smtpServer').value.trim();
                const smtpPort = parseInt(document.getElementById('smtpPort').value);
                const smtpUsername = document.getElementById('smtpUsername').value.trim();
                const smtpPassword = document.getElementById('smtpPassword').value;
                
                if (enabled && (!email || !smtpServer || !smtpPort || !smtpUsername || !smtpPassword)) {
                    showAdminAlert('error', 'All fields are required when boot notifications are enabled');
                    return;
                }
                
                const response = await fetch('/api/admin/boot-notification', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        enabled: enabled,
                        email: email,
                        smtp_server: smtpServer,
                        smtp_port: smtpPort,
                        smtp_username: smtpUsername,
                        smtp_password: smtpPassword
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    showAdminAlert('success', data.message);
                    clearAdminForm();
                } else {
                    showAdminAlert('error', data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error saving boot notification settings: ' + error.message);
            }
        }
        
        async function testBootNotification() {
            try {
                showAdminAlert('info', 'Sending test notification...');
                
                const response = await fetch('/api/admin/test-boot-notification', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' }
                });
                
                const data = await response.json();
                
                if (data.success) {
                    showAdminAlert('success', data.message);
                } else {
                    showAdminAlert('error', data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error sending test notification: ' + error.message);
            }
        }

'''

# Find a good place to insert the JavaScript functions
# Look for existing admin functions or insert before closing script tag
if '// Admin panel network rename functions' in content:
    content = content.replace('// Admin panel network rename functions', js_functions + '\n        // Admin panel network rename functions')
else:
    # Fallback: insert before closing script tag
    content = content.replace('</script>', js_functions + '\n    </script>')

# Write the updated content
with open('index.html', 'w') as f:
    f.write(content)

print("✅ Admin panel HTML updated successfully!")
EOF

# Run the Python script
echo "🔧 Applying admin panel improvements..."
python3 fix_admin_panel.py

# Clean up
rm fix_admin_panel.py

# Restart dashboard service
echo "🔄 Restarting dashboard service..."
sudo systemctl start eero-dashboard.service

# Wait for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet eero-dashboard.service; then
    echo "✅ Dashboard service restarted successfully"
else
    echo "❌ Dashboard service failed to start, restoring backup..."
    cp index.html.backup.* index.html
    sudo systemctl start eero-dashboard.service
    exit 1
fi

# Get IP address for access
WLAN_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)
ETH_IP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n1)

echo ""
echo "🎉 Admin Panel Fixed Successfully!"
echo "================================="
echo ""
echo "📋 Improvements Applied:"
echo "   ✅ Clean, organized layout with sections"
echo "   ✅ Interface Access Controls button added"
echo "   ✅ Boot Notification Settings button added"
echo "   ✅ Professional visual design"
echo "   ✅ Mobile-friendly responsive layout"
echo ""
echo "🌐 Access Your Dashboard:"
if [[ -n "$WLAN_IP" ]]; then
    echo "   WiFi:     https://$WLAN_IP"
fi
if [[ -n "$ETH_IP" ]]; then
    echo "   Ethernet: https://$ETH_IP"
fi
echo ""
echo "🔧 Click the π (pi) icon to see the improved admin panel!"
echo ""
echo "📋 New Admin Panel Sections:"
echo "   • System Management - Updates, Interface Controls, Boot Notifications"
echo "   • Network Configuration - Networks, Authentication"  
echo "   • Display & Interface - Kiosk Mode, Timezone"