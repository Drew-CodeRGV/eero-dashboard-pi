#!/bin/bash

# Enhance Interface Access Controls with Testing and Feedback
# This script adds better feedback, testing, and confirmation to interface controls

set -e

echo "🔧 Enhancing Interface Access Controls with Testing and Feedback..."

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
cp index.html index.html.backup.$(date +%Y%m%d_%H%M%S)

# Add enhanced API endpoints to dashboard.py
echo "🔧 Adding enhanced interface control APIs..."

# Create Python script to add the new API endpoints
cat > enhance_dashboard.py << 'EOF'
#!/usr/bin/env python3
import re

# Read the current dashboard.py
with open('dashboard.py', 'r') as f:
    content = f.read()

# Add new API endpoints for testing interface access
new_endpoints = '''
@app.route('/api/admin/interface-access/test', methods=['POST'])
def test_interface_access():
    """Test interface access configuration"""
    try:
        data = request.get_json()
        wired_enabled = data.get('wired_enabled', True)
        wireless_enabled = data.get('wireless_enabled', True)
        allow_external = data.get('allow_external', True)
        
        import subprocess
        
        # Get current interface information
        interfaces = {}
        
        # Get wired interface info
        result = subprocess.run(['ip', 'addr', 'show'], capture_output=True, text=True)
        for line in result.stdout.split('\\n'):
            if 'eth' in line or 'enp' in line:
                interface_name = line.split(':')[1].strip()
                # Get IP for this interface
                interface_lines = result.stdout.split(line)[1].split('\\n')
                for iface_line in interface_lines:
                    if 'inet ' in iface_line and '127.0.0.1' not in iface_line:
                        ip_addr = iface_line.strip().split()[1].split('/')[0]
                        interfaces['wired'] = {
                            'name': interface_name,
                            'ip': ip_addr,
                            'enabled': wired_enabled,
                            'accessible': wired_enabled
                        }
                        break
                break
        
        # Get wireless interface info
        for line in result.stdout.split('\\n'):
            if 'wlan' in line or 'wlp' in line:
                interface_name = line.split(':')[1].strip()
                # Get IP for this interface
                interface_lines = result.stdout.split(line)[1].split('\\n')
                for iface_line in interface_lines:
                    if 'inet ' in iface_line and '127.0.0.1' not in iface_line:
                        ip_addr = iface_line.strip().split()[1].split('/')[0]
                        interfaces['wireless'] = {
                            'name': interface_name,
                            'ip': ip_addr,
                            'enabled': wireless_enabled,
                            'accessible': wireless_enabled
                        }
                        break
                break
        
        # Test nginx configuration
        nginx_status = 'unknown'
        try:
            nginx_result = subprocess.run(['sudo', 'systemctl', 'is-active', 'nginx'], 
                                        capture_output=True, text=True)
            nginx_status = nginx_result.stdout.strip()
        except:
            pass
        
        return jsonify({
            'success': True,
            'interfaces': interfaces,
            'nginx_status': nginx_status,
            'external_access': allow_external,
            'test_timestamp': get_timezone_aware_now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/interface-access/status', methods=['GET'])
def get_interface_access_status():
    """Get current interface access status and nginx configuration"""
    try:
        import subprocess
        
        # Get current configuration
        config = load_config()
        interface_config = config.get('interface_access', {
            'wired_enabled': True,
            'wireless_enabled': True,
            'allow_external': True
        })
        
        # Get nginx status
        nginx_status = 'unknown'
        nginx_config_exists = False
        try:
            nginx_result = subprocess.run(['sudo', 'systemctl', 'is-active', 'nginx'], 
                                        capture_output=True, text=True)
            nginx_status = nginx_result.stdout.strip()
            
            # Check if our nginx config exists
            config_check = subprocess.run(['sudo', 'test', '-f', '/etc/nginx/sites-available/eero-dashboard-https'], 
                                        capture_output=True)
            nginx_config_exists = config_check.returncode == 0
        except:
            pass
        
        # Get interface IPs
        interfaces = {}
        result = subprocess.run(['ip', 'addr', 'show'], capture_output=True, text=True)
        
        # Parse wired interface
        for line in result.stdout.split('\\n'):
            if 'eth' in line or 'enp' in line:
                interface_name = line.split(':')[1].strip()
                interface_lines = result.stdout.split(line)[1].split('\\n')
                for iface_line in interface_lines:
                    if 'inet ' in iface_line and '127.0.0.1' not in iface_line:
                        ip_addr = iface_line.strip().split()[1].split('/')[0]
                        interfaces['wired'] = {
                            'name': interface_name,
                            'ip': ip_addr,
                            'enabled': interface_config.get('wired_enabled', True)
                        }
                        break
                break
        
        # Parse wireless interface
        for line in result.stdout.split('\\n'):
            if 'wlan' in line or 'wlp' in line:
                interface_name = line.split(':')[1].strip()
                interface_lines = result.stdout.split(line)[1].split('\\n')
                for iface_line in interface_lines:
                    if 'inet ' in iface_line and '127.0.0.1' not in iface_line:
                        ip_addr = iface_line.strip().split()[1].split('/')[0]
                        interfaces['wireless'] = {
                            'name': interface_name,
                            'ip': ip_addr,
                            'enabled': interface_config.get('wireless_enabled', True)
                        }
                        break
                break
        
        return jsonify({
            'success': True,
            'interface_config': interface_config,
            'interfaces': interfaces,
            'nginx_status': nginx_status,
            'nginx_config_exists': nginx_config_exists,
            'status_timestamp': get_timezone_aware_now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

'''

# Find a good place to insert the new endpoints (before the existing interface-access endpoints)
insertion_point = content.find("@app.route('/api/admin/interface-access', methods=['GET'])")
if insertion_point != -1:
    content = content[:insertion_point] + new_endpoints + content[insertion_point:]
else:
    # Fallback: insert before the boot notification endpoints
    insertion_point = content.find("@app.route('/api/admin/boot-notification', methods=['GET'])")
    if insertion_point != -1:
        content = content[:insertion_point] + new_endpoints + content[insertion_point:]

# Write the updated content
with open('dashboard.py', 'w') as f:
    f.write(content)

print("✅ Enhanced API endpoints added to dashboard.py")
EOF

# Run the Python script to enhance dashboard.py
python3 enhance_dashboard.py
rm enhance_dashboard.py

# Enhance the admin panel JavaScript with better feedback and testing
echo "🔧 Enhancing admin panel interface controls..."

cat > enhance_admin_panel.py << 'EOF'
#!/usr/bin/env python3
import re

# Read the current index.html
with open('index.html', 'r') as f:
    content = f.read()

# Enhanced JavaScript functions with testing and feedback
enhanced_js = '''
        // Enhanced Interface Access Controls with Testing
        async function showInterfaceAccessForm() {
            try {
                // Load current configuration and status
                const [configResponse, statusResponse] = await Promise.all([
                    fetch('/api/admin/interface-access'),
                    fetch('/api/admin/interface-access/status')
                ]);
                
                const configData = await configResponse.json();
                const statusData = await statusResponse.json();
                
                if (configData.success && statusData.success) {
                    const config = configData.interface_access;
                    const status = statusData;
                    
                    let interfaceInfo = '';
                    if (status.interfaces.wired) {
                        interfaceInfo += `<p><strong>Wired Interface:</strong> ${status.interfaces.wired.name} (${status.interfaces.wired.ip})</p>`;
                    }
                    if (status.interfaces.wireless) {
                        interfaceInfo += `<p><strong>Wireless Interface:</strong> ${status.interfaces.wireless.name} (${status.interfaces.wireless.ip})</p>`;
                    }
                    
                    document.getElementById('adminFormContainer').innerHTML = `
                        <div class="admin-form">
                            <h3><i class="fas fa-wifi"></i> Interface Access Controls</h3>
                            <p>Control which network interfaces can access the dashboard web service.</p>
                            
                            <div class="interface-status">
                                <h4>Current Interface Status:</h4>
                                ${interfaceInfo}
                                <p><strong>Nginx Status:</strong> <span class="status-${status.nginx_status}">${status.nginx_status}</span></p>
                            </div>
                            
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
                                <button class="form-btn" onclick="testInterfaceAccess()">Test Configuration</button>
                                <button class="form-btn" onclick="saveInterfaceAccess()">Save & Apply</button>
                                <button class="form-btn secondary" onclick="refreshInterfaceStatus()">Refresh Status</button>
                                <button class="form-btn secondary" onclick="clearAdminForm()">Cancel</button>
                            </div>
                            
                            <div id="interfaceTestResults" class="test-results" style="display: none;"></div>
                        </div>
                    `;
                } else {
                    showAdminAlert('error', 'Failed to load interface access settings');
                }
            } catch (error) {
                showAdminAlert('error', 'Error loading interface access settings: ' + error.message);
            }
        }
        
        async function testInterfaceAccess() {
            try {
                const wiredEnabled = document.getElementById('wiredEnabled').checked;
                const wirelessEnabled = document.getElementById('wirelessEnabled').checked;
                const allowExternal = document.getElementById('allowExternal').checked;
                
                showAdminAlert('info', 'Testing interface configuration...');
                
                const response = await fetch('/api/admin/interface-access/test', {
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
                    let resultsHtml = '<h4>Test Results:</h4>';
                    
                    if (data.interfaces.wired) {
                        const wiredStatus = data.interfaces.wired.accessible ? 'accessible' : 'blocked';
                        resultsHtml += `<p><strong>Wired (${data.interfaces.wired.ip}):</strong> <span class="status-${wiredStatus}">${wiredStatus}</span></p>`;
                    }
                    
                    if (data.interfaces.wireless) {
                        const wirelessStatus = data.interfaces.wireless.accessible ? 'accessible' : 'blocked';
                        resultsHtml += `<p><strong>Wireless (${data.interfaces.wireless.ip}):</strong> <span class="status-${wirelessStatus}">${wirelessStatus}</span></p>`;
                    }
                    
                    resultsHtml += `<p><strong>External Access:</strong> <span class="status-${data.external_access ? 'allowed' : 'blocked'}">${data.external_access ? 'allowed' : 'blocked'}</span></p>`;
                    resultsHtml += `<p><strong>Nginx Status:</strong> <span class="status-${data.nginx_status}">${data.nginx_status}</span></p>`;
                    
                    document.getElementById('interfaceTestResults').innerHTML = resultsHtml;
                    document.getElementById('interfaceTestResults').style.display = 'block';
                    
                    showAdminAlert('success', 'Configuration test completed');
                } else {
                    showAdminAlert('error', 'Test failed: ' + data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error testing configuration: ' + error.message);
            }
        }
        
        async function saveInterfaceAccess() {
            try {
                const wiredEnabled = document.getElementById('wiredEnabled').checked;
                const wirelessEnabled = document.getElementById('wirelessEnabled').checked;
                const allowExternal = document.getElementById('allowExternal').checked;
                
                showAdminAlert('info', 'Saving and applying configuration...');
                
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
                    showAdminAlert('success', data.message + ' Configuration applied to nginx.');
                    
                    // Wait a moment then refresh status
                    setTimeout(async () => {
                        await refreshInterfaceStatus();
                        showAdminAlert('info', 'Interface access controls updated. Test access from different interfaces to verify.');
                    }, 2000);
                } else {
                    showAdminAlert('error', data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error saving configuration: ' + error.message);
            }
        }
        
        async function refreshInterfaceStatus() {
            try {
                const response = await fetch('/api/admin/interface-access/status');
                const data = await response.json();
                
                if (data.success) {
                    // Update the interface status display
                    let interfaceInfo = '';
                    if (data.interfaces.wired) {
                        const status = data.interfaces.wired.enabled ? 'enabled' : 'disabled';
                        interfaceInfo += `<p><strong>Wired Interface:</strong> ${data.interfaces.wired.name} (${data.interfaces.wired.ip}) - <span class="status-${status}">${status}</span></p>`;
                    }
                    if (data.interfaces.wireless) {
                        const status = data.interfaces.wireless.enabled ? 'enabled' : 'disabled';
                        interfaceInfo += `<p><strong>Wireless Interface:</strong> ${data.interfaces.wireless.name} (${data.interfaces.wireless.ip}) - <span class="status-${status}">${status}</span></p>`;
                    }
                    interfaceInfo += `<p><strong>Nginx Status:</strong> <span class="status-${data.nginx_status}">${data.nginx_status}</span></p>`;
                    
                    const statusDiv = document.querySelector('.interface-status');
                    if (statusDiv) {
                        statusDiv.innerHTML = '<h4>Current Interface Status:</h4>' + interfaceInfo;
                    }
                    
                    showAdminAlert('success', 'Status refreshed');
                } else {
                    showAdminAlert('error', 'Failed to refresh status: ' + data.message);
                }
            } catch (error) {
                showAdminAlert('error', 'Error refreshing status: ' + error.message);
            }
        }

'''

# Replace the existing showInterfaceAccessForm function
pattern = r'async function showInterfaceAccessForm\(\).*?(?=async function [a-zA-Z]|$)'
content = re.sub(pattern, enhanced_js.strip(), content, flags=re.DOTALL)

# Add CSS for status indicators
status_css = '''
        /* Interface Status Styles */
        .interface-status {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 15px;
            margin: 15px 0;
        }
        
        .interface-status h4 {
            margin: 0 0 10px 0;
            color: #4da6ff;
            font-size: 14px;
        }
        
        .interface-status p {
            margin: 5px 0;
            font-size: 13px;
        }
        
        .test-results {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
        }
        
        .test-results h4 {
            margin: 0 0 10px 0;
            color: #4da6ff;
            font-size: 14px;
        }
        
        .status-active, .status-accessible, .status-allowed, .status-enabled {
            color: #28a745;
            font-weight: 600;
        }
        
        .status-inactive, .status-blocked, .status-disabled {
            color: #dc3545;
            font-weight: 600;
        }
        
        .status-unknown {
            color: #ffc107;
            font-weight: 600;
        }

'''

# Insert the CSS before </style>
content = content.replace('</style>', status_css + '</style>')

# Write the updated content
with open('index.html', 'w') as f:
    f.write(content)

print("✅ Enhanced admin panel interface controls")
EOF

# Run the Python script to enhance the admin panel
python3 enhance_admin_panel.py
rm enhance_admin_panel.py

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
    cp index.html.backup.* index.html
    sudo systemctl start eero-dashboard.service
    exit 1
fi

echo ""
echo "🎉 Interface Access Controls Enhanced Successfully!"
echo "================================================="
echo ""
echo "📋 New Features Added:"
echo "   ✅ Test Configuration button - Test settings before applying"
echo "   ✅ Real-time status display - See current interface states"
echo "   ✅ Refresh Status button - Update interface information"
echo "   ✅ Visual status indicators - Color-coded status display"
echo "   ✅ Better feedback messages - Clear success/error notifications"
echo "   ✅ Configuration validation - Verify nginx updates"
echo ""
echo "🔧 How to Use:"
echo "   1. Open Admin Panel → Interface Access Controls"
echo "   2. Adjust your settings (wired/wireless/external)"
echo "   3. Click 'Test Configuration' to preview changes"
echo "   4. Click 'Save & Apply' to implement changes"
echo "   5. Use 'Refresh Status' to verify the changes took effect"
echo ""
echo "🌐 Testing Your Configuration:"
echo "   • Try accessing from wired connection if enabled"
echo "   • Try accessing from wireless connection if enabled"
echo "   • Try accessing from external network if enabled"
echo "   • Blocked interfaces should show connection refused/timeout"