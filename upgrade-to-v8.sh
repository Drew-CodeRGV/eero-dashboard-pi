#!/bin/bash

# eero Dashboard Pi - Upgrade to Version 8.0
# One-command upgrade script for existing installations

set -e

echo "🚀 Upgrading eero Dashboard Pi to Version 8.0"
echo "=============================================="
echo ""
echo "New Features in Version 8.0:"
echo "✅ Interface Access Controls"
echo "✅ Enhanced Boot Notifications with HTML emails"
echo "✅ Network Data Purging"
echo "✅ Professional Admin Panel"
echo "✅ Lightning-Fast Deployment"
echo ""

# Check if we're in the right directory
if [[ ! -f "dashboard.py" ]]; then
    echo "❌ Please run this script from the eero-dashboard directory"
    echo "   cd ~/eero-dashboard"
    echo "   ./upgrade-to-v8.sh"
    exit 1
fi

# Backup current installation
echo "📋 Creating backup..."
BACKUP_DIR="v7-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ~/.eero-dashboard "$BACKUP_DIR/config" 2>/dev/null || true
cp dashboard.py "$BACKUP_DIR/" 2>/dev/null || true
cp index.html "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup created: $BACKUP_DIR"

# Pull latest version
echo "📥 Updating to Version 8.0..."
git pull

# Check version
NEW_VERSION=$(python3 -c "from dashboard import VERSION; print(VERSION)" 2>/dev/null || echo "unknown")
echo "✅ Updated to version: $NEW_VERSION"

# Run deployment readiness (installs new features)
echo "🔧 Installing Version 8.0 features..."
./fix-deployment-ready.sh

echo ""
echo "🎉 Upgrade to Version 8.0 Complete!"
echo "===================================="
echo ""
echo "📋 What's New:"
echo "   • Interface Access Controls in Admin Panel"
echo "   • Boot Notification Settings with email configuration"
echo "   • Enhanced network management with data purging"
echo "   • Professional admin panel layout"
echo ""
echo "🔧 Next Steps:"
echo "   1. Open dashboard in web browser"
echo "   2. Click π (pi) icon for Admin Panel"
echo "   3. Configure Interface Access Controls"
echo "   4. Set up Boot Notification Settings"
echo "   5. Test email functionality"
echo ""
echo "📧 Configure Boot Notifications:"
echo "   • Admin Panel → System Management → Boot Notification Settings"
echo "   • Enter your email and SMTP settings"
echo "   • Use 'Send Test Email' to verify"
echo ""
echo "🔐 Configure Interface Controls:"
echo "   • Admin Panel → System Management → Interface Access Controls"
echo "   • Test configuration before applying"
echo "   • Control wired/wireless/external access"
echo ""
echo "📖 Documentation:"
echo "   • VERSION_8_RELEASE_NOTES.md - Complete feature overview"
echo "   • VERSION_8_UPGRADE_GUIDE.md - Detailed upgrade instructions"
echo "   • DEPLOYMENT_V8.md - New deployment capabilities"
echo ""
echo "🎯 Version 8.0 is ready! Enjoy the enhanced deployment and management features!"