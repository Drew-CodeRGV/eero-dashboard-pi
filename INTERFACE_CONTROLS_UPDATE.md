# Interface Access Controls and Boot Notification Update

This update adds two major new features to your Eero Dashboard:

## 🆕 New Features

### 1. Interface Access Controls
- Control which network interfaces can access the dashboard web service
- Enable/disable access via wired interface (Ethernet)
- Enable/disable access via wireless interface (WiFi)
- Control external access from other networks
- **Both wired and wireless interfaces are enabled by default**

### 2. Boot Notification System
- Automatically sends email notifications when the dashboard starts up
- Includes IP addresses of all network interfaces
- Configurable SMTP settings for any email provider
- **Email sent to drew@drewlentz.com by default**
- Test email functionality to verify settings

## 🚀 Installation Instructions

### Quick Update (Recommended)
Run this single command on your Raspberry Pi:

```bash
cd ~/eero-dashboard && git pull && ./update-with-interface-controls.sh
```

### Manual Step-by-Step
If you prefer to do it manually:

```bash
# 1. Navigate to dashboard directory
cd ~/eero-dashboard

# 2. Pull latest changes
git pull

# 3. Run the comprehensive update script
./update-with-interface-controls.sh
```

## 🔧 Configuration

After installation:

1. **Open the dashboard** in your web browser
2. **Click the π (pi) icon** to open the Admin Panel
3. **Configure Interface Access Controls:**
   - Choose which interfaces can access the dashboard
   - Both wired and wireless are enabled by default
4. **Configure Boot Notification Settings:**
   - Enable/disable boot notifications
   - Set your email address (defaults to drew@drewlentz.com)
   - Configure SMTP settings (Gmail, Outlook, etc.)
   - Use "Send Test Email" to verify settings work

## 📧 Email Configuration

### For Gmail:
- SMTP Server: `smtp.gmail.com`
- SMTP Port: `587`
- Username: Your Gmail address
- Password: Use an **App Password** (not your regular password)

### For Outlook/Hotmail:
- SMTP Server: `smtp-mail.outlook.com`
- SMTP Port: `587`
- Username: Your Outlook address
- Password: Your regular password

## 🔍 Verification

### Check Dashboard Service:
```bash
sudo systemctl status eero-dashboard.service
```

### Check Boot Notification Service:
```bash
sudo systemctl status boot-notification.service
```

### View Logs:
```bash
# Dashboard logs
sudo journalctl -u eero-dashboard.service -f

# Boot notification logs
sudo journalctl -u boot-notification.service -f
```

### Test Boot Notification:
```bash
# Manually trigger boot notification
sudo systemctl start boot-notification.service
```

## 🌐 Access Dashboard

After update, access your dashboard at:
- **HTTPS (recommended):** `https://[your-pi-ip]`
- **HTTP (redirects to HTTPS):** `http://[your-pi-ip]`

## 🆘 Troubleshooting

### If Dashboard Won't Start:
```bash
# Check service status
sudo systemctl status eero-dashboard.service

# View recent logs
sudo journalctl -u eero-dashboard.service -n 50

# Restart service
sudo systemctl restart eero-dashboard.service
```

### If Boot Notifications Don't Work:
1. Check email settings in Admin Panel
2. For Gmail, ensure you're using an App Password
3. Test with "Send Test Email" button
4. Check boot notification logs:
   ```bash
   sudo journalctl -u boot-notification.service -n 20
   ```

### If Interface Controls Don't Apply:
- Changes to interface controls require nginx reload
- The update script handles this automatically
- Manual reload: `sudo systemctl reload nginx`

## 📋 What This Update Includes

### New Files:
- `boot-notification.py` - Boot notification service script
- `boot-notification.service` - Systemd service configuration
- `setup-boot-notification.sh` - Boot notification setup script
- `add-admin-interface-controls.sh` - Admin panel UI updater
- `update-with-interface-controls.sh` - Comprehensive update script

### Updated Files:
- `dashboard.py` - Added interface controls and boot notification APIs
- `index.html` - Added admin panel UI for new features (via script)

### New Admin Panel Features:
- **Interface Access Controls** button
- **Boot Notification Settings** button
- Test email functionality
- Real-time configuration updates

## 🎉 Enjoy Your Enhanced Dashboard!

Your Eero Dashboard now has professional-grade interface controls and boot notification capabilities. The system will automatically notify you via email whenever it starts up, including all IP addresses for easy remote access.