#!/bin/bash

# Fix and Clean Up Admin Panel Layout
# This script reorganizes the admin panel with proper categories and adds missing buttons

set -e

echo "🎨 Fixing and cleaning up Admin Panel layout..."

# Check if we're in the correct directory
if [[ ! -f "index.html" ]]; then
    echo "❌ index.html not found. Please run this script from the eero-dashboard-pi directory."
    exit 1
fi

# Create backup of index.html
echo "📋 Creating backup of index.html..."
cp index.html index.html.backup.$(date +%Y%m%d_%H%M%S)

# Create the new organized admin menu structure
cat > temp_admin_menu.html << 'EOF'
            <div class="admin-menu">
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
            </div>
EOF

# Replace the existing admin menu with the new organized version
sed -i '/<div class="admin-menu">/,/<\/div>/c\
'"$(cat temp_admin_menu.html)" index.html

# Add CSS for the new admin sections
cat > temp_admin_styles.css << 'EOF'

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
        
        /* Improved admin button styling */
        .admin-btn {
            display: flex;
            align-items: center;
            justify-content: flex-start;
            padding: 12px 15px;
            background: rgba(77, 166, 255, 0.15);
            border: 1px solid rgba(77, 166, 255, 0.3);
            border-radius: 8px;
            color: #ffffff;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            gap: 12px;
            min-height: 44px;
        }
        
        .admin-btn:hover {
            background: rgba(77, 166, 255, 0.25);
            border-color: rgba(77, 166, 255, 0.5);
            transform: translateX(3px);
        }
        
        .admin-btn i {
            font-size: 16px;
            width: 20px;
            text-align: center;
            flex-shrink: 0;
            color: #4da6ff;
        }
        
        .admin-btn span {
            flex: 1;
            text-align: left;
        }
        
        /* Mobile responsiveness */
        @media (max-width: 768px) {
            .admin-section {
                margin-bottom: 20px;
                padding: 12px;
            }
            
            .admin-section-title {
                font-size: 15px;
                margin-bottom: 12px;
            }
            
            .admin-btn {
                padding: 10px 12px;
                font-size: 13px;
                gap: 10px;
            }
            
            .admin-btn i {
                font-size: 15px;
                width: 18px;
            }
        }

EOF

# Insert the new CSS before the closing style tag
sed -i '/<\/style>/i\
'"$(cat temp_admin_styles.css)" index.html

# Add the missing JavaScript functions for interface controls and boot notifications
cat > temp_admin_functions.js << 'EOF'

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

# Find the right place to insert the new functions (before the closing script tag)
# Look for existing admin functions and insert before them
INSERTION_POINT=$(grep -n "// Admin panel network rename functions" index.html | cut -d: -f1)

if [[ -n "$INSERTION_POINT" ]]; then
    # Insert the new functions before the network rename functions
    sed -i "${INSERTION_POINT}i\\$(cat temp_admin_functions.js)" index.html
else
    # Fallback: insert before the closing script tag
    sed -i '/<\/script>/i\
'"$(cat temp_admin_functions.js)" index.html
fi

# Add additional CSS for form elements
cat > temp_form_styles.css << 'EOF'

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
        
        .admin-form p {
            margin: 0 0 20px 0;
            color: #b0b0b0;
            font-size: 14px;
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
        
        .form-group input[type="text"],
        .form-group input[type="email"],
        .form-group input[type="number"],
        .form-group input[type="password"] {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 6px;
            background: rgba(255, 255, 255, 0.1);
            color: #ffffff;
            font-size: 14px;
            box-sizing: border-box;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #4da6ff;
            background: rgba(255, 255, 255, 0.15);
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
        
        .form-group small {
            display: block;
            margin-top: 5px;
            font-size: 12px;
            color: #888;
            font-style: italic;
        }
        
        .form-actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        
        .form-btn {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            background: #4da6ff;
            color: #ffffff;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            min-height: 40px;
        }
        
        .form-btn:hover {
            background: #3d8bff;
            transform: translateY(-1px);
        }
        
        .form-btn.secondary {
            background: #6c757d;
        }
        
        .form-btn.secondary:hover {
            background: #5a6268;
        }
        
        /* Mobile form adjustments */
        @media (max-width: 768px) {
            .admin-form {
                padding: 15px;
                margin-top: 15px;
            }
            
            .form-actions {
                flex-direction: column;
            }
            
            .form-btn {
                width: 100%;
            }
        }

EOF

# Insert the form CSS before the closing style tag
sed -i '/<\/style>/i\
'"$(cat temp_form_styles.css)" index.html

# Clean up temporary files
rm temp_admin_menu.html temp_admin_styles.css temp_admin_functions.js temp_form_styles.css

echo "✅ Admin Panel layout fixed and cleaned up!"
echo ""
echo "📋 Improvements Made:"
echo "   ✅ Organized buttons into logical sections:"
echo "      • System Management (Updates, Interface Controls, Boot Notifications)"
echo "      • Network Configuration (Networks, Authentication)"
echo "      • Display & Interface (Kiosk Mode, Timezone)"
echo "   ✅ Added missing Interface Access Controls button"
echo "   ✅ Added missing Boot Notification Settings button"
echo "   ✅ Improved visual design with section headers"
echo "   ✅ Enhanced mobile responsiveness"
echo "   ✅ Added proper form styling"
echo ""
echo "🔧 The admin panel now has a clean, professional layout!"
echo "   Click the π (pi) icon to see the improved interface"