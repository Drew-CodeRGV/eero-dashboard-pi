# eero Dashboard Pi - Version 8.0 Upgrade Guide

## 🚀 Upgrading to Version 8.0.0

This guide will help you upgrade your existing eero Dashboard Pi installation to version 8.0.0, which introduces interface access controls and enhanced boot notifications.

---

## 📋 Pre-Upgrade Checklist

### 1. Check Current Version
```bash
cd ~/eero-dashboard
python3 -c "from dashboard import VERSION; print(f'Current version: {VERSION}')"
```

### 2. Backup Current Installation
```bash
# Backup configuration and data
cp -r ~/.eero-dashboard ~/.eero-dashboard.backup.$(date +%Y%m%d)

# Backup dashboard files
cp dashboard.py dashboard.py.backup.$(date +%Y%m%d)
cp index.html index.html.backup.$(date +%Y%m%d)

# Backup service configuration
sudo cp /etc/systemd/system/eero-dashboard.service /etc/systemd/system/eero-dashboard.service.backup
```

### 3. Note Current Settings
- Network configurations
- Timezone settings
- Kiosk mode settings
- Any custom modifications

---

## 🔄 Upgrade Methods

### Method 1: Automatic Upgrade (Recommended)

#### Single Command Upgrade
```bash
cd ~/eero-dashboard && git pull && ./fix-deployment-ready.sh
```

This command will:
- ✅ Pull latest code from repository
- ✅ Install missing services
- ✅ Enable auto-start for all services
- ✅ Verify configuration
- ✅ Test functionality

#### If the above fails, try the step-by-step approach:

```bash
# 1. Navigate to dashboard directory
cd ~/eero-dashboard

# 2. Pull latest changes
git pull

# 3. Run deployment readiness script
./fix-deployment-ready.sh
```

### Method 2: Enhanced Feature Installation

If you want to add the new features to an existing installation:

```bash
cd ~/eero-dashboard

# Add enhanced boot notifications with clickable links
wget -O enhance-boot-notification.sh https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/enhance-boot-notification.sh
chmod +x enhance-boot-notification.sh
./enhance-boot-notification.sh

# Add interface access controls with testing
wget -O enhance-interface-controls.sh https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/enhance-interface-controls.sh
chmod +x enhance-interface-controls.sh
./enhance-interface-controls.sh

# Fix admin panel layout
wget -O simple-admin-panel-fix.sh https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/simple-admin-panel-fix.sh
chmod +x simple-admin-panel-fix.sh
./simple-admin-panel-fix.sh
```

### Method 3: Fresh Installation (If upgrade fails)

```bash
# 1. Stop current services
sudo systemctl stop eero-dashboard.service
sudo systemctl stop nginx

# 2. Backup and remove old installation
mv ~/eero-dashboard ~/eero-dashboard.old

# 3. Fresh installation
git clone https://github.com/Drew-CodeRGV/eero-dashboard-pi.git ~/eero-dashboard
cd ~/eero-dashboard
sudo ./install.sh

# 4. Restore configuration
cp ~/.eero-dashboard.backup/* ~/.eero-dashboard/
```

---

## 🔧 Post-Upgrade Configuration

### 1. Verify Services
```bash
# Check all services are running
sudo systemctl status eero-dashboard.service
sudo systemctl status boot-notification.service
sudo systemctl status nginx
sudo systemctl status ssh

# Check service auto-start is enabled
sudo systemctl is-enabled eero-dashboard.service
sudo systemctl is-enabled boot-notification.service
sudo systemctl is-enabled nginx
sudo systemctl is-enabled ssh
```

### 2. Configure New Features

#### Interface Access Controls
1. Open dashboard in web browser
2. Click π (pi) icon for Admin Panel
3. Go to **System Management** → **Interface Access Controls**
4. Configure your preferred settings:
   - ✅ Wired Interface Access (default: enabled)
   - ✅ Wireless Interface Access (default: enabled)
   - ✅ External Network Access (default: enabled)
5. Click **Test Configuration** to preview changes
6. Click **Save & Apply** to implement

#### Boot Notification Settings
1. In Admin Panel, go to **System Management** → **Boot Notification Settings**
2. Configure email settings:
   - ✅ Enable boot notifications
   - 📧 Notification email: drew@drewlentz.com (or your email)
   - 🔧 SMTP server: smtp.gmail.com (or your provider)
   - 🔢 SMTP port: 587
   - 👤 SMTP username: your email
   - 🔑 SMTP password: your app password
3. Click **Send Test Email** to verify functionality
4. Click **Save Settings**

### 3. Test New Functionality

#### Test Interface Controls
```bash
# Check current interface status
curl -s http://localhost/api/admin/interface-access/status | python3 -m json.tool

# Test web access from different interfaces
# (Try accessing from wired and wireless connections)
```

#### Test Boot Notifications
```bash
# Manual test
cd ~/eero-dashboard
python3 -c "from boot_notification import send_boot_notification; send_boot_notification(test_mode=True)"

# Or use admin panel "Send Test Email" button
```

---

## 🆕 New Features Overview

### Interface Access Controls
- **Purpose**: Control which network interfaces can access the dashboard
- **Location**: Admin Panel → System Management → Interface Access Controls
- **Features**:
  - Enable/disable wired interface access
  - Enable/disable wireless interface access
  - Control external network access
  - Real-time configuration testing
  - Visual status indicators

### Enhanced Boot Notifications
- **Purpose**: Get notified when Pi boots with clickable dashboard links
- **Location**: Admin Panel → System Management → Boot Notification Settings
- **Features**:
  - HTML email with professional styling
  - Clickable dashboard links for instant access
  - SSH connection information
  - Individual links for each network interface
  - System status and information

### Network Data Purging
- **Purpose**: Complete cleanup when networks are deleted
- **Location**: Admin Panel → Network Configuration → Manage Networks
- **Features**:
  - Removes API tokens and cached data
  - Purges log file entries
  - Cleans temporary files
  - Detailed purge reporting

### Enhanced Admin Panel
- **Purpose**: Better organization and user experience
- **Location**: Click π (pi) icon in dashboard
- **Features**:
  - Organized sections (System/Network/Display)
  - Professional visual design
  - Mobile-responsive layout
  - Better feedback and validation

---

## 🔍 Troubleshooting

### Common Upgrade Issues

#### 1. Git Pull Conflicts
```bash
# If git pull fails with conflicts
cd ~/eero-dashboard
git stash
git pull
git stash pop

# Or force update
git fetch origin
git reset --hard origin/main
```

#### 2. Service Installation Failures
```bash
# If boot-notification.service fails to install
cd ~/eero-dashboard
sudo cp boot-notification.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable boot-notification.service
```

#### 3. Dashboard Won't Start
```bash
# Check for errors
sudo journalctl -u eero-dashboard.service -n 50

# Try restarting
sudo systemctl restart eero-dashboard.service

# Check nginx
sudo systemctl status nginx
sudo nginx -t
```

#### 4. Admin Panel Issues
```bash
# Clear browser cache and reload
# Or try incognito/private browsing mode

# Check if admin panel files are updated
grep -q "Interface Access Controls" ~/eero-dashboard/index.html && echo "✅ Updated" || echo "❌ Not updated"
```

### Rollback Procedure

If you need to rollback to the previous version:

```bash
# 1. Stop services
sudo systemctl stop eero-dashboard.service
sudo systemctl stop boot-notification.service

# 2. Restore files
cp dashboard.py.backup.* dashboard.py
cp index.html.backup.* index.html

# 3. Restore configuration
cp -r ~/.eero-dashboard.backup/* ~/.eero-dashboard/

# 4. Restart services
sudo systemctl start eero-dashboard.service
sudo systemctl start nginx
```

---

## ✅ Verification Checklist

After upgrading, verify these items:

### Services
- [ ] eero-dashboard.service is running and enabled
- [ ] boot-notification.service is installed and enabled
- [ ] nginx is running and enabled
- [ ] ssh is running and enabled

### Dashboard Access
- [ ] Dashboard loads in web browser
- [ ] Admin panel opens (π icon)
- [ ] All existing networks are visible
- [ ] Device data is displaying correctly

### New Features
- [ ] Interface Access Controls section exists in admin panel
- [ ] Boot Notification Settings section exists in admin panel
- [ ] Test Configuration button works
- [ ] Send Test Email button works
- [ ] Network deletion shows purge information

### Configuration
- [ ] All previous settings are preserved
- [ ] Network authentication still works
- [ ] Timezone settings are correct
- [ ] Kiosk mode settings are preserved (if used)

---

## 📞 Getting Help

### If Upgrade Fails
1. **Check the logs**:
   ```bash
   sudo journalctl -u eero-dashboard.service -f
   ```

2. **Run diagnostic script**:
   ```bash
   ./fix-deployment-ready.sh
   ```

3. **Try fresh installation** (as last resort):
   - Backup your configuration
   - Remove old installation
   - Fresh install from repository
   - Restore configuration

### Support Resources
- **GitHub Issues**: Report problems and get help
- **Documentation**: Check README.md and other guides
- **Community**: Share experiences and solutions

### Quick Commands for Support
```bash
# System information
uname -a
python3 --version
systemctl --version

# Service status
sudo systemctl status eero-dashboard.service
sudo systemctl status boot-notification.service
sudo systemctl status nginx

# Dashboard version
cd ~/eero-dashboard
python3 -c "from dashboard import VERSION; print(f'Version: {VERSION}')"

# Recent logs
sudo journalctl -u eero-dashboard.service -n 20 --no-pager
```

---

## 🎉 Welcome to Version 8.0!

Congratulations on upgrading to eero Dashboard Pi version 8.0! You now have:

- ✅ **Professional interface access controls**
- ✅ **Enhanced boot notifications with clickable links**
- ✅ **Complete network data management**
- ✅ **Improved admin panel experience**
- ✅ **Deployment-optimized workflows**

Enjoy the enhanced functionality and improved deployment capabilities!