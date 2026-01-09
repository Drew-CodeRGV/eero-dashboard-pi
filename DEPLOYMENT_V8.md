# eero Dashboard Pi - Version 8.0 Deployment Guide

## 🚀 Lightning-Fast Deployment with Version 8.0

Version 8.0 introduces revolutionary deployment capabilities with clickable boot notifications and professional interface controls, making Pi deployment faster and more efficient than ever.

---

## 📋 Deployment Overview

### Traditional Deployment (Pre-v8.0)
1. Deploy Pi to location
2. Find Pi's IP address manually
3. SSH in to configure
4. Open web browser with IP
5. Configure dashboard manually

**Time: 15-30 minutes**

### Version 8.0 Deployment
1. Deploy Pi to location
2. Receive email with clickable dashboard links
3. Click link to open dashboard immediately
4. Start monitoring instantly

**Time: 2-3 minutes**

---

## 🔧 Pre-Deployment Setup

### 1. Initial Pi Configuration

#### Fresh Installation
```bash
# Clone repository
git clone https://github.com/Drew-CodeRGV/eero-dashboard-pi.git
cd eero-dashboard-pi

# Install dashboard
sudo ./install.sh

# Upgrade to version 8.0 features
./fix-deployment-ready.sh
```

#### Upgrade Existing Installation
```bash
cd ~/eero-dashboard
git pull
./fix-deployment-ready.sh
```

### 2. Configure Boot Notifications

#### Email Settings
1. **Open Dashboard** → Click π (pi) icon
2. **Navigate** → System Management → Boot Notification Settings
3. **Configure**:
   - ✅ Enable boot notifications
   - 📧 Email: drew@drewlentz.com (or your email)
   - 🔧 SMTP Server: smtp.gmail.com
   - 🔢 Port: 587
   - 👤 Username: your-email@gmail.com
   - 🔑 Password: your-app-password

#### Gmail App Password Setup
```bash
# For Gmail users:
# 1. Go to Google Account settings
# 2. Security → 2-Step Verification
# 3. App passwords → Generate password
# 4. Use generated password in dashboard
```

#### Test Email Functionality
1. Click **"Send Test Email"** in admin panel
2. Check your email for test notification
3. Verify clickable links work
4. Confirm SSH information is correct

### 3. Configure Interface Access (Optional)

#### Default Settings (Recommended)
- ✅ Wired Interface Access: Enabled
- ✅ Wireless Interface Access: Enabled
- ✅ External Network Access: Enabled

#### Custom Configuration
1. **Navigate** → Admin Panel → Interface Access Controls
2. **Adjust Settings** based on security requirements
3. **Test Configuration** before applying
4. **Save & Apply** changes

### 4. Verify Deployment Readiness

```bash
cd ~/eero-dashboard
./fix-deployment-ready.sh
```

This script will:
- ✅ Check all services are enabled for auto-start
- ✅ Test boot notification functionality
- ✅ Verify SSH access
- ✅ Confirm web services are running
- ✅ Display network information

---

## 🚀 Deployment Process

### Step 1: Prepare for Deployment
```bash
# Final readiness check
cd ~/eero-dashboard
./fix-deployment-ready.sh

# Shutdown Pi
sudo shutdown -h now
```

### Step 2: Physical Deployment
1. **Transport Pi** to deployment location
2. **Connect Network** (Ethernet cable or ensure WiFi access)
3. **Connect Power** and wait for boot

### Step 3: Receive Boot Notification

#### Email Content Example
```
🚀 eero Dashboard Ready - raspberrypi

Your Raspberry Pi dashboard is online and ready to use

[Open Dashboard] [Admin Panel]

Network Interfaces:
• wlan0 (Wireless): 192.168.1.100 [Open Dashboard]
• eth0 (Wired): 192.168.1.101 [Open Dashboard]

SSH Access: ssh wifi@192.168.1.100

Quick Setup Steps:
1. Click dashboard link above
2. Click π icon for admin panel
3. Add your eero networks
4. Authenticate and configure
```

### Step 4: Instant Access
1. **Click "Open Dashboard"** in email
2. **Dashboard opens** immediately in browser
3. **Click π icon** for admin panel
4. **Add networks** and authenticate
5. **Start monitoring** - fully operational!

---

## 🌐 Network Configuration Scenarios

### Scenario 1: Wired Network Deployment
```
Physical Setup:
• Pi connected via Ethernet cable
• Static or DHCP IP assignment
• Router/switch with internet access

Boot Notification Will Show:
• eth0 (Wired): 192.168.1.100 [Open Dashboard]
• SSH: ssh wifi@192.168.1.100

Access Method:
• Click wired interface link in email
• Dashboard opens immediately
```

### Scenario 2: Wireless Network Deployment
```
Physical Setup:
• Pi connects to existing WiFi network
• WiFi credentials pre-configured
• Wireless router with internet access

Boot Notification Will Show:
• wlan0 (Wireless): 192.168.1.100 [Open Dashboard]
• SSH: ssh wifi@192.168.1.100

Access Method:
• Click wireless interface link in email
• Dashboard opens immediately
```

### Scenario 3: Dual Interface Deployment
```
Physical Setup:
• Pi connected to both wired and wireless
• Multiple network access paths
• Redundant connectivity

Boot Notification Will Show:
• wlan0 (Wireless): 192.168.1.100 [Open Dashboard]
• eth0 (Wired): 192.168.1.101 [Open Dashboard]
• SSH: ssh wifi@192.168.1.100

Access Method:
• Choose preferred interface link
• Both links work independently
```

---

## 🔒 Security Considerations

### Interface Access Controls

#### High Security Deployment
```
Configuration:
• Wired Interface Access: ✅ Enabled
• Wireless Interface Access: ❌ Disabled
• External Network Access: ❌ Disabled

Use Case:
• Internal corporate networks
• Secure facility monitoring
• Air-gapped environments
```

#### Balanced Security Deployment
```
Configuration:
• Wired Interface Access: ✅ Enabled
• Wireless Interface Access: ✅ Enabled
• External Network Access: ❌ Disabled

Use Case:
• Home networks
• Small office deployments
• Trusted environments
```

#### Open Access Deployment
```
Configuration:
• Wired Interface Access: ✅ Enabled
• Wireless Interface Access: ✅ Enabled
• External Network Access: ✅ Enabled

Use Case:
• Remote monitoring
• Multi-site deployments
• Public network access needed
```

### SSH Security
```bash
# Change default password immediately
passwd

# Disable password authentication (use keys)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart ssh

# Configure firewall (optional)
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
```

---

## 📊 Multi-Site Deployment

### Deployment Strategy
1. **Configure Master Pi** with all settings
2. **Create SD Card Image** for replication
3. **Deploy Multiple Pis** with identical configuration
4. **Receive Boot Notifications** for each Pi with unique IPs
5. **Manage All Sites** via dashboard links in emails

### Master Pi Setup
```bash
# 1. Complete configuration
cd ~/eero-dashboard
./fix-deployment-ready.sh

# 2. Test all functionality
# 3. Create SD card image
sudo dd if=/dev/mmcblk0 of=eero-dashboard-master.img bs=4M

# 4. Deploy image to multiple SD cards
sudo dd if=eero-dashboard-master.img of=/dev/sdX bs=4M
```

### Site Management
- Each Pi sends boot notification with its unique IP
- Bookmark dashboard links for quick access
- Use SSH commands from emails for remote management
- Monitor all sites from centralized location

---

## 🔧 Troubleshooting Deployment

### Boot Notification Not Received

#### Check Email Configuration
```bash
# Test email settings
cd ~/eero-dashboard
python3 -c "from boot_notification import send_boot_notification; send_boot_notification(test_mode=True)"

# Check service status
sudo systemctl status boot-notification.service

# View logs
sudo journalctl -u boot-notification.service -f
```

#### Common Issues
- **SMTP credentials incorrect** → Verify username/password
- **Network connectivity delayed** → Wait longer for boot
- **Email in spam folder** → Check spam/junk mail
- **Service not enabled** → Run `./fix-deployment-ready.sh`

### Dashboard Not Accessible

#### Check Web Services
```bash
# Check dashboard service
sudo systemctl status eero-dashboard.service

# Check nginx
sudo systemctl status nginx

# Test local access
curl -I http://localhost/health
```

#### Network Issues
- **IP address changed** → Check router DHCP settings
- **Firewall blocking** → Configure firewall rules
- **Interface disabled** → Check interface access controls
- **Network configuration** → Verify network settings

### SSH Access Issues

#### Check SSH Service
```bash
# Verify SSH is running
sudo systemctl status ssh

# Check SSH configuration
sudo sshd -T | grep -i passwordauth

# Test local SSH
ssh localhost
```

#### Connection Problems
- **Wrong IP address** → Use IP from boot notification email
- **Password changed** → Use correct password or SSH keys
- **SSH disabled** → Enable SSH service
- **Network routing** → Check network connectivity

---

## 📈 Performance Optimization

### Boot Time Optimization
```bash
# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon

# Optimize boot parameters
sudo nano /boot/cmdline.txt
# Add: quiet splash

# Reduce boot delay
sudo nano /boot/config.txt
# Add: boot_delay=0
```

### Network Optimization
```bash
# Set static IP (optional)
sudo nano /etc/dhcpcd.conf
# Add:
# interface eth0
# static ip_address=192.168.1.100/24
# static routers=192.168.1.1
# static domain_name_servers=8.8.8.8

# Optimize network settings
echo 'net.core.rmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
```

### Dashboard Performance
```bash
# Optimize Python performance
export PYTHONOPTIMIZE=1

# Reduce log verbosity (production)
sudo nano ~/.eero-dashboard/config.json
# Set log level to WARNING or ERROR
```

---

## 🎯 Deployment Scenarios

### Home Network Monitoring
```
Setup:
• Single Pi deployment
• WiFi connection to home router
• Monitor family eero network
• Email notifications to personal email

Configuration:
• All interfaces enabled
• Boot notifications enabled
• Standard security settings

Deployment Time: 2-3 minutes
```

### Small Office Deployment
```
Setup:
• Multiple Pi deployment
• Wired connections preferred
• Monitor office eero networks
• Email notifications to IT team

Configuration:
• Wired interface priority
• External access disabled
• Enhanced security settings

Deployment Time: 5 minutes per site
```

### Remote Site Monitoring
```
Setup:
• Distributed Pi deployment
• Mixed wired/wireless connections
• Monitor multiple eero networks
• Centralized email notifications

Configuration:
• All interfaces enabled
• Boot notifications critical
• Remote management optimized

Deployment Time: 3-5 minutes per site
```

### Enterprise Deployment
```
Setup:
• Large-scale Pi deployment
• Standardized configurations
• Corporate network integration
• Automated management

Configuration:
• Security-focused settings
• Centralized logging
• Interface access controls
• Automated deployment

Deployment Time: 2 minutes per unit (after setup)
```

---

## 📞 Support and Maintenance

### Regular Maintenance
```bash
# Weekly health check
cd ~/eero-dashboard
./fix-deployment-ready.sh

# Update dashboard
git pull

# Check logs
sudo journalctl -u eero-dashboard.service -n 50

# Test email notifications
# Use admin panel "Send Test Email"
```

### Remote Management
```bash
# SSH into Pi (from boot notification email)
ssh wifi@[ip-from-email]

# Check status
sudo systemctl status eero-dashboard.service

# Restart services if needed
sudo systemctl restart eero-dashboard.service
sudo systemctl restart nginx

# Update configuration via web interface
# Use dashboard links from boot notification
```

### Backup and Recovery
```bash
# Backup configuration
cp -r ~/.eero-dashboard ~/.eero-dashboard.backup

# Backup dashboard files
cp dashboard.py dashboard.py.backup
cp index.html index.html.backup

# Create full system backup (optional)
sudo dd if=/dev/mmcblk0 of=backup.img bs=4M
```

---

## 🎉 Deployment Success

With eero Dashboard Pi version 8.0, you now have:

- ✅ **Lightning-fast deployment** with clickable email links
- ✅ **Professional interface controls** for security
- ✅ **Automated boot notifications** with system information
- ✅ **Remote management capabilities** via SSH and web interface
- ✅ **Multi-site deployment support** with centralized monitoring

**Deploy once, monitor everywhere!**