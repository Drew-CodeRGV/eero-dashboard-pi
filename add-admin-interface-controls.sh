#!/bin/bash

# Add Interface Access Controls and Boot Notification to Admin Panel
# This script adds the new admin panel features to index.html

set -e

echo "🔧 Adding Interface Access Controls and Boot Notification to Admin Panel..."

# Check if we're in the correct directory
if [[ ! -f "index.html" ]]; then
    echo "❌ index.html not found. Please run this script from the eero-dashboard-pi directory."
    exit 1
fi

# Create backup of index.html
echo "📋 Creating backup of index.html..."
cp index.html index.html.backup.$(date +%Y%m%d_%H%M%S)

# Add the new admin buttons after the existing ones
echo "🔧 Adding new admin buttons..."

# Find the line with the Legacy Reauthorize button and add new buttons after it
sed -i '/onclick="showReauthorizeForm()"/a\
                <button class="admin-btn" onclick="showInterfaceAccessForm()">\
                    <i class="fas fa-wifi"></i><span>Interface Access Controls</span>\
                </button>\
                <button class="admin-btn" onclick="showBootNotificationForm()">\
                    <i class="fas fa-envelope"></i><span>Boot Notification Settings</span>\
                </button>' index.html

# Add the JavaScript functions for the new features
echo "🔧 Adding JavaScript functions..."

# Find the end of the existing admin functions and add new ones
cat >> temp_admin_functions.js << 'EOF'

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

EOF

# Find the last admin function and insert the new functions before the closing script tag
# Look for the end of the admin functions section
INSERTION_POINT=$(grep -n "// Admin panel network rename functions" index.html | cut -d: -f1)

if [[ -n "$INSERTION_POINT" ]]; then
    # Insert the new functions before the network rename functions
    sed -i "${INSERTION_POINT}i\\$(cat temp_admin_functions.js)" index.html
else
    # Fallback: insert before the closing script tag
    sed -i '/<\/script>/i\
'"$(cat temp_admin_functions.js)" index.html
fi

# Clean up temporary file
rm temp_admin_functions.js

# Add CSS styles for the new form elements
echo "🎨 Adding CSS styles..."

# Find the CSS section and add new styles
cat >> temp_admin_styles.css << 'EOF'

        /* Interface Access and Boot Notification Form Styles */
        .checkbox-label {
            display: flex;
            align-items: center;
            cursor: pointer;
            margin-bottom: 10px;
            font-size: 14px;
        }
        
        .checkbox-label input[type="checkbox"] {
            margin-right: 10px;
            transform: scale(1.2);
        }
        
        .form-group small {
            display: block;
            margin-top: 5px;
            font-size: 12px;
            color: #666;
            font-style: italic;
        }
        
        .form-actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }
        
        .form-btn.secondary {
            background-color: #6c757d;
        }
        
        .form-btn.secondary:hover {
            background-color: #5a6268;
        }

EOF

# Insert the CSS before the closing style tag
sed -i '/<\/style>/i\
'"$(cat temp_admin_styles.css)" index.html

# Clean up temporary file
rm temp_admin_styles.css

echo "✅ Interface Access Controls and Boot Notification added to Admin Panel!"
echo ""
echo "📋 New Features Added:"
echo "   • Interface Access Controls - Control wired/wireless access"
echo "   • Boot Notification Settings - Configure startup email notifications"
echo ""
echo "🔧 Both features are now available in the Admin Panel (π button)"
echo ""
echo "⚠️  Note: Restart the dashboard service to ensure all changes take effect:"
echo "   sudo systemctl restart eero-dashboard.service"