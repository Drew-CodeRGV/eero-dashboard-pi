#!/bin/bash

# Quick Update Script for Interface Controls and Boot Notification
# Run this on your Raspberry Pi to get the latest features

set -e

echo "🚀 Getting Interface Controls and Boot Notification Update..."

# Check if we're in the right directory
if [[ ! -f "dashboard.py" ]]; then
    echo "❌ Please run this script from the eero-dashboard directory"
    echo "   cd ~/eero-dashboard"
    echo "   ./get-interface-controls-update.sh"
    exit 1
fi

# Backup any conflicting files
echo "📋 Backing up any local files that might conflict..."
if [[ -f "configure-network-binding.sh" ]] || [[ -f "setup-ssl.sh" ]] || [[ -f "test-voice-endpoints.sh" ]]; then
    BACKUP_DIR="local-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    [[ -f "configure-network-binding.sh" ]] && mv configure-network-binding.sh "$BACKUP_DIR/"
    [[ -f "setup-ssl.sh" ]] && mv setup-ssl.sh "$BACKUP_DIR/"
    [[ -f "test-voice-endpoints.sh" ]] && mv test-voice-endpoints.sh "$BACKUP_DIR/"
    
    echo "✅ Local files backed up to: $BACKUP_DIR"
fi

# Pull the latest updates
echo "📥 Pulling latest updates from repository..."
git pull

# Check if the update script exists
if [[ ! -f "update-with-interface-controls.sh" ]]; then
    echo "❌ Update script not found. The repository may not have been updated yet."
    echo "   Please try again in a few minutes."
    exit 1
fi

# Make sure the update script is executable
chmod +x update-with-interface-controls.sh

# Run the comprehensive update
echo "🔧 Running comprehensive update..."
./update-with-interface-controls.sh

echo ""
echo "🎉 Update completed successfully!"
echo ""
echo "📋 New Features Available:"
echo "   ✅ Interface Access Controls (Admin Panel → Interface Access Controls)"
echo "   ✅ Boot Notification System (Admin Panel → Boot Notification Settings)"
echo ""
echo "🔧 Next Steps:"
echo "   1. Open your dashboard in a web browser"
echo "   2. Click the π (pi) icon to open Admin Panel"
echo "   3. Configure your new features!"