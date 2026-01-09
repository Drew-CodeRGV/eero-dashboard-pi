# Eero Network Dashboard for Raspberry Pi

A professional network monitoring dashboard designed specifically for Raspberry Pi deployment. Monitor multiple Eero networks with real-time device tracking, AP capacity visualization, and kiosk mode for digital signage.

## 🚀 Features

### **Core Dashboard**
- **Real-time Network Monitoring**: Live device counts, OS distribution, frequency analysis
- **Multi-Network Support**: Monitor up to 6 networks simultaneously
- **Professional UI**: Official Eero brand colors and enterprise-grade design
- **Responsive Design**: Optimized for all screen sizes

### **AP Capacity Visualization**
- **Real-time AP Data**: Live device distribution across access points
- **Color-coded APs**: Visual indication of AP load using Eero brand colors
- **Frequency Breakdown**: 2.4GHz, 5GHz, and 6GHz device distribution
- **Sorted Display**: APs ordered by device count for priority identification

### **Kiosk Mode**
- **Automatic Switching**: Seamless transitions between dashboard and capacity views
- **Configurable Timers**: Customizable display duration (1-60 seconds each)
- **Seamless Transitions**: Pre-loaded data eliminates loading delays
- **Perfect for Digital Signage**: Professional unattended display mode

### **Network Management**
- **Network Sorting**: Networks ordered by device count (most to least)
- **Inline Renaming**: Easy network name editing in dashboard and admin panel
- **Authentication Management**: Individual network API token handling
- **Status Indicators**: Clear connected/disconnected network status

## 📋 Requirements

### **Hardware**
- Raspberry Pi 3B+ or newer (Pi 4 recommended)
- MicroSD card (16GB minimum, 32GB recommended)
- Network connection (Ethernet or WiFi)

### **Software**
- Raspberry Pi OS (Bullseye or newer)
- Python 3.7+
- Internet connection for Eero API access

## 🔧 Installation

### **Quick Install (Recommended)**
```bash
# Download and run the installation script
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/install.sh | bash
```

### **Manual Installation**
```bash
# Clone the repository
git clone https://github.com/your-username/eero-dashboard-pi.git
cd eero-dashboard-pi

# Run the setup script
chmod +x setup.sh
./setup.sh
```

### **What the installer does:**
1. Updates system packages
2. Installs Python dependencies
3. Creates systemd service for auto-start
4. Sets up log rotation
5. Configures firewall (optional)
6. Creates desktop shortcut

## 🎯 Quick Start

### **1. Initial Setup**
After installation, the dashboard will be available at:
- **Local**: http://localhost
- **Network**: http://[pi-ip-address]

### **2. Configure Networks**
1. Click the **π** button to open admin panel
2. Click **"Manage Networks"**
3. Add your Eero network(s):
   - Enter Network ID (found in Eero app)
   - Enter email address for authentication
   - Give network a friendly name
4. Authenticate each network with email verification

### **3. Enable Kiosk Mode (Optional)**
1. Configure display timings in **π** → **"Kiosk Mode Settings"**
2. Click the **TV** icon to start automatic switching
3. Perfect for wall-mounted displays and digital signage

## 🎨 Screenshots

### Dashboard View
![Dashboard](screenshots/dashboard.png)
*Real-time network monitoring with device counts and frequency distribution*

### AP Capacity View
![AP Capacity](screenshots/ap-capacity.png)
*Live AP device distribution with color-coded load indicators*

### Kiosk Mode
![Kiosk Mode](screenshots/kiosk-mode.png)
*Automatic switching between views for unattended displays*

### Admin Panel
![Admin Panel](screenshots/admin-panel.png)
*Comprehensive network management and configuration*

## 🔧 Configuration

### **Network Settings**
- **Multi-Network**: Support for up to 6 Eero networks
- **Custom Names**: User-defined network names for easy identification
- **Authentication**: Individual API tokens per network
- **Active/Inactive**: Toggle networks on/off without removing

### **Kiosk Mode**
- **Dashboard Time**: 1-60 seconds (default: 5s)
- **Capacity Time**: 1-60 seconds (default: 7s)
- **Seamless Switching**: Pre-loaded data for instant transitions

### **Display Options**
- **Time Ranges**: Historical data from 1 hour to 1 week
- **Auto-refresh**: Live updates every 60 seconds
- **Responsive**: Adapts to screen size automatically

## 🛠️ Advanced Configuration

### **Service Management**
```bash
# Check service status
sudo systemctl status eero-dashboard

# Start/stop service
sudo systemctl start eero-dashboard
sudo systemctl stop eero-dashboard

# Enable/disable auto-start
sudo systemctl enable eero-dashboard
sudo systemctl disable eero-dashboard

# View logs
sudo journalctl -u eero-dashboard -f
```

### **Configuration Files**
- **Main Config**: `~/.eero-dashboard/config.json`
- **Network Tokens**: `~/.eero-dashboard/.eero_token_[network_id]`
- **Logs**: `~/.eero-dashboard/dashboard.log`

### **Port Configuration**
The dashboard runs on port 80 (standard HTTP port) by default. This requires the service to run as root for security reasons. The systemd service is configured to handle this automatically.

## 🔒 Security

### **API Security**
- Network tokens stored securely with 600 permissions
- No passwords stored locally
- Uses official Eero API endpoints
- HTTPS communication with Eero servers

### **Network Security**
- Dashboard runs on local network only
- No external data transmission except to Eero API
- Optional firewall configuration included
- Regular security updates recommended

## 📊 Performance

### **Optimized for Pi**
- Efficient data caching reduces API calls
- Background updates don't block UI
- Memory usage optimized for Pi hardware
- Automatic cleanup of old log files

### **Resource Usage**
- **RAM**: ~50-100MB typical usage
- **CPU**: <5% on Pi 4, <10% on Pi 3B+
- **Storage**: ~50MB for application + logs
- **Network**: Minimal (API calls every 60s)

## 🐛 Troubleshooting

### **Quick Fix for Common Issues**
If the dashboard service fails to start, run this quick fix script:
```bash
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/quick-fix.sh | bash
```

### **Comprehensive Diagnostics**
For detailed troubleshooting and diagnostics:
```bash
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/diagnose-and-fix.sh | bash
```

### **Common Issues**

**Dashboard won't start:**
```bash
# Check service status
sudo systemctl status eero-dashboard

# Check logs for errors
sudo journalctl -u eero-dashboard -n 50
```

**Can't access from other devices:**
```bash
# Check if service is running on correct port
sudo netstat -tlnp | grep :80

# Check firewall (if enabled)
sudo ufw status
```

**Authentication fails:**
1. Verify network ID is correct (from Eero app)
2. Check email address is associated with Eero account
3. Ensure network has internet connectivity
4. Try re-authentication in admin panel

**Performance issues:**
1. Check available RAM: `free -h`
2. Monitor CPU usage: `htop`
3. Check SD card health: `sudo dmesg | grep mmc`
4. Consider Pi 4 for better performance

### **Getting Help**
- **Issues**: [GitHub Issues](https://github.com/Drew-CodeRGV/eero-dashboard-pi/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Drew-CodeRGV/eero-dashboard-pi/discussions)
- **Documentation**: [Wiki](https://github.com/Drew-CodeRGV/eero-dashboard-pi/wiki)

## 🔄 Updates

### **Automatic Updates**
The dashboard checks for updates automatically. To update manually:
```bash
cd eero-dashboard-pi
git pull origin main
sudo systemctl restart eero-dashboard
```

### **Version History**
- **v7.0.14**: Admin panel network renaming
- **v7.0.13**: Seamless kiosk transitions with data caching
- **v7.0.12**: Kiosk mode with configurable timers
- **v7.0.11**: Network renaming functionality
- **v7.0.10**: Improved spacing and professional layout

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### **Development Setup**
```bash
# Clone repository
git clone https://github.com/Drew-CodeRGV/eero-dashboard-pi.git
cd eero-dashboard-pi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run in development mode
python dashboard.py
```

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Eero**: For providing the API that makes this dashboard possible
- **Chart.js**: For beautiful, responsive charts
- **Flask**: For the lightweight web framework
- **Raspberry Pi Foundation**: For creating amazing hardware for projects like this

## 📞 Support

- **Documentation**: [Wiki](https://github.com/Drew-CodeRGV/eero-dashboard-pi/wiki)
- **Bug Reports**: [Issues](https://github.com/Drew-CodeRGV/eero-dashboard-pi/issues)
- **Feature Requests**: [Discussions](https://github.com/Drew-CodeRGV/eero-dashboard-pi/discussions)
- **Email**: support@your-domain.com

---

**Made with ❤️ for the Raspberry Pi and Eero communities**