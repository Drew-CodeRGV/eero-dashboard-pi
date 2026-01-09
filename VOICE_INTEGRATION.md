# Voice Integration for Amazon Echo

Add voice control to your Raspberry Pi Eero Dashboard using Amazon Echo/Alexa.

## Quick Setup

Run this command on your Raspberry Pi to add voice endpoints:

```bash
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/add-voice-endpoints.sh | bash
```

## What This Does

- ✅ Adds 4 voice-optimized API endpoints to your dashboard
- ✅ Creates automatic backup of your dashboard.py
- ✅ Restarts the dashboard service
- ✅ Tests the new endpoints

## New API Endpoints

After running the script, these endpoints will be available:

- `GET /api/voice/status` - Network status for voice responses
- `GET /api/voice/devices` - Device information optimized for speech
- `GET /api/voice/aps` - Access point performance data
- `GET /api/voice/events` - Recent network events

## Test the Installation

```bash
# Download and run the test script
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/test-voice-endpoints.sh | bash

# Or test manually
curl http://$(hostname -I | awk '{print $1}')/api/voice/status
```

## Voice Commands

Once you set up the Alexa skill, you can use commands like:

- *"Alexa, ask Eero Dashboard how many devices are connected"*
- *"Alexa, ask Eero Dashboard what's my network status"*
- *"Alexa, ask Eero Dashboard about device types"*
- *"Alexa, ask Eero Dashboard how are my access points performing"*

## Next Steps

1. ✅ Run the voice endpoint installation (above)
2. 🎤 Set up the [Alexa skill](https://github.com/Drew-CodeRGV/eero-event-dashboard-echo)
3. 🗣️ Start using voice commands!

## Troubleshooting

### Script fails to run
```bash
# Make sure you're the wifi user
sudo su - wifi

# Then run the script again
curl -sSL https://raw.githubusercontent.com/Drew-CodeRGV/eero-dashboard-pi/main/add-voice-endpoints.sh | bash
```

### Voice endpoints not working
```bash
# Check dashboard status
sudo systemctl status eero-dashboard

# Test endpoints
curl http://localhost/api/voice/status

# Restart if needed
sudo systemctl restart eero-dashboard
```

### Need to remove voice endpoints
```bash
# Restore from backup
sudo cp /home/wifi/eero-dashboard/backups/dashboard.py.backup.* /home/wifi/eero-dashboard/dashboard.py
sudo systemctl restart eero-dashboard
```

## Manual Installation

If you prefer to add the endpoints manually, see the [full integration guide](https://github.com/Drew-CodeRGV/eero-event-dashboard-echo/blob/main/SETUP_GUIDE.md).

---

**🎤 Ready to control your network with your voice!**