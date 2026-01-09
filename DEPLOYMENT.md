# Eero Dashboard - Raspberry Pi Deployment Guide

## 🚀 Quick Deployment

### Option 1: Automated Installation (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/eero-drew/eero-dashboard-pi/main/install.sh | bash
```

### Option 2: Manual Installation
```bash
git clone https://github.com/eero-drew/eero-dashboard-pi.git
cd eero-dashboard-pi
chmod +x setup.sh
./setup.sh
```

## 📋 Pre-Installation Checklist

### Hardware Requirements
- [ ] Raspberry Pi 3B+ or newer (Pi 4 recommended)
- [ ] MicroSD card (16GB minimum, 32GB recommended)
- [ ] Stable network connection (Ethernet preferred)
- [ ] Power supply (official Pi power supply recommended)

### Software Requirements
- [ ] Raspberry Pi OS (Bullseye or newer)
- [ ] Python 3.7+ (usually pre-installed)
- [ ] Internet connection for package installation
- [ ] SSH access (if installing remotely)

### Network Requirements
- [ ] Access to Eero network(s) you want to monitor
- [ ] Email address associated with Eero account
- [ ] Network ID(s) from Eero mobile app

## 🔧 Installation Process

### Step 1: System Preparation
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required system packages
sudo apt install -y python3-pip python3-venv git curl

# Optional: Install additional tools
sudo apt install -y htop nano vim
```

### Step 2: Download and Install
```bash
# Method 1: Automated installer
curl -sSL https://raw.githubusercontent.com/eero-drew/eero-dashboard-pi/main/install.sh | bash

# Method 2: Manual installation
git clone https://github.com/eero-drew/eero-dashboard-pi.git
cd eero-dashboard-pi
./setup.sh
```

### Step 3: Verify Installation
```bash
# Test the installation
python3 test.py

# Check service status
sudo systemctl status eero-dashboard

# View logs
sudo journalctl -u eero-dashboard -f
```

### Step 4: Initial Configuration
1. Open browser to `http://[pi-ip]:5000`
2. Click the π (Pi) button to open admin panel
3. Add your Eero network(s):
   - Enter Network ID (from Eero app)
   - Enter email address
   - Give network a friendly name
4. Authenticate each network via email verification

## 🌐 Network Access

### Local Access
- **URL**: `http://localhost:5000`
- **Use**: Direct access from Pi desktop

### Remote Access
- **URL**: `http://[pi-ip-address]:5000`
- **Find IP**: `hostname -I` or check router admin panel
- **Use**: Access from other devices on same network

### Firewall Configuration (Optional)
```bash
# Install UFW if not present
sudo apt install -y ufw

# Allow dashboard port
sudo ufw allow 5000/tcp comment "Eero Dashboard"

# Enable firewall
sudo ufw enable
```

## 🔒 Security Considerations

### Network Security
- Dashboard runs on local network only by default
- No external internet exposure unless configured
- Uses HTTPS for all Eero API communications
- Tokens stored with restricted file permissions (600)

### Access Control
- Consider changing default port if needed
- Use strong passwords for Pi user account
- Keep system updated with security patches
- Monitor access logs if needed

### Data Privacy
- All network data stays on your local Pi
- No data transmitted to third parties
- Eero API tokens stored locally only
- Optional: Enable SSH key authentication

## 📊 Performance Optimization

### For Raspberry Pi 3B+
```bash
# Increase GPU memory split
echo "gpu_mem=16" | sudo tee -a /boot/config.txt

# Optimize Python performance
echo "export PYTHONOPTIMIZE=1" >> ~/.bashrc
```

### For Raspberry Pi 4
```bash
# Enable 64-bit kernel (if using 32-bit OS)
echo "arm_64bit=1" | sudo tee -a /boot/config.txt

# Increase GPU memory for better performance
echo "gpu_mem=32" | sudo tee -a /boot/config.txt
```

### Storage Optimization
```bash
# Move logs to RAM disk (optional)
echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0" | sudo tee -a /etc/fstab

# Enable log rotation
sudo systemctl enable logrotate
```

## 🔄 Maintenance

### Regular Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update dashboard (if using git)
cd ~/eero-dashboard
git pull origin main
sudo systemctl restart eero-dashboard
```

### Log Management
```bash
# View current logs
sudo journalctl -u eero-dashboard -n 100

# Clear old logs
sudo journalctl --vacuum-time=7d

# Check log disk usage
sudo journalctl --disk-usage
```

### Backup Configuration
```bash
# Backup configuration
cp -r ~/.eero-dashboard ~/.eero-dashboard.backup

# Backup to external storage
rsync -av ~/.eero-dashboard /media/usb/eero-backup/
```

## 🐛 Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status eero-dashboard

# View detailed logs
sudo journalctl -u eero-dashboard -n 50

# Restart service
sudo systemctl restart eero-dashboard
```

### Cannot Access Dashboard
```bash
# Check if port is open
sudo netstat -tlnp | grep :5000

# Check firewall
sudo ufw status

# Test local connection
curl http://localhost:5000/health
```

### Authentication Issues
1. Verify network ID is correct (from Eero app)
2. Check email address is associated with Eero account
3. Ensure Pi has internet connectivity
4. Try re-authentication in admin panel

### Performance Issues
```bash
# Check system resources
htop

# Check disk space
df -h

# Check memory usage
free -h

# Monitor service performance
sudo systemctl status eero-dashboard
```

## 📱 Mobile Access

### Responsive Design
- Dashboard automatically adapts to mobile screens
- Touch-friendly interface for tablets
- Optimized for both portrait and landscape modes

### Mobile Browser Tips
- Add to home screen for app-like experience
- Use landscape mode for best chart visibility
- Kiosk mode works great on tablets

## 🖥️ Kiosk Mode Setup

### For Digital Signage
1. Configure kiosk timers in admin panel
2. Set up auto-login on Pi
3. Configure browser to start in fullscreen
4. Enable kiosk mode in dashboard

### Auto-Start Browser (Optional)
```bash
# Install chromium
sudo apt install -y chromium-browser

# Create autostart script
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/dashboard.desktop << EOF
[Desktop Entry]
Type=Application
Name=Dashboard
Exec=chromium-browser --start-fullscreen --kiosk http://localhost:5000
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
```

## 📞 Support

### Getting Help
- **Documentation**: Check README.md and wiki
- **Issues**: Report bugs on GitHub Issues
- **Discussions**: Ask questions on GitHub Discussions
- **Logs**: Always include logs when reporting issues

### Useful Commands
```bash
# Service management
sudo systemctl {start|stop|restart|status} eero-dashboard

# View logs
sudo journalctl -u eero-dashboard -f

# Test installation
python3 test.py

# Check system status
htop
df -h
free -h
```

---

**🎉 Congratulations!** Your Eero Dashboard should now be running successfully on your Raspberry Pi. Enjoy monitoring your network!