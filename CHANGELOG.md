# Changelog

All notable changes to the eero Dashboard Pi project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [8.0.0] - 2026-01-09

### 🚀 Major Release: Interface Controls & Boot Notifications

#### Added
- **Interface Access Controls**
  - Network interface management (wired/wireless/external access)
  - Real-time configuration testing and validation
  - Visual status indicators with color coding
  - Automatic nginx configuration updates
  - Admin panel integration with organized sections

- **Enhanced Boot Notification System**
  - HTML email notifications with professional styling
  - Clickable dashboard links for instant access
  - SSH connection information in emails
  - Multi-interface support with individual links
  - Deployment-optimized workflow

- **Network Data Purging**
  - Complete data cleanup when networks are deleted
  - Log file purging and sanitization
  - Cache management and token cleanup
  - Detailed purge reporting

- **Enhanced Admin Panel**
  - Organized layout with System/Network/Display sections
  - Professional visual design and mobile responsiveness
  - Improved feedback and status indicators
  - Form validation and user guidance

- **New API Endpoints**
  - `/api/admin/interface-access` - Interface access management
  - `/api/admin/interface-access/test` - Configuration testing
  - `/api/admin/interface-access/status` - Real-time status
  - `/api/admin/boot-notification` - Notification settings
  - `/api/admin/test-boot-notification` - Email testing

- **Deployment Tools**
  - `fix-deployment-ready.sh` - Deployment readiness verification
  - `enhance-boot-notification.sh` - Boot notification enhancement
  - `enhance-interface-controls.sh` - Interface controls enhancement
  - `simple-admin-panel-fix.sh` - Admin panel layout fixes

#### Changed
- Updated version to 8.0.0-interface-controls-boot-notifications
- Enhanced network removal with complete data purging
- Improved admin panel organization and styling
- Consistent lowercase "eero" branding throughout
- Enhanced boot notification service with HTML email support

#### Fixed
- Missing boot-notification.service installation
- Admin panel layout and functionality issues
- Interface access control feedback and testing
- Service dependency management
- Email notification reliability

#### Security
- IP-based access control implementation
- Secure SMTP credential handling
- Complete data sanitization on network removal
- Enhanced nginx security configuration

## [7.0.14] - 2025-12-XX

### Added
- Multi-network support and management
- Network renaming functionality
- Voice API endpoints for Alexa integration
- HTTPS/SSL support with nginx proxy
- Kiosk mode for display deployments

### Changed
- Improved network authentication flow
- Enhanced mobile responsiveness
- Better error handling and logging

### Fixed
- Network switching and data isolation
- Authentication token management
- Mobile display issues

## [7.0.0] - 2025-11-XX

### Added
- Raspberry Pi optimization
- Systemd service integration
- Professional dashboard interface
- Multi-network monitoring
- Access point capacity visualization

### Changed
- Migrated from development to production deployment
- Enhanced performance for Pi hardware
- Improved data caching and management

## [6.9.0] - 2025-10-XX

### Added
- Mobile swipe navigation
- Enhanced device tracking
- Signal strength monitoring
- Frequency band analysis

### Changed
- Improved mobile user interface
- Better data visualization
- Enhanced responsive design

## [6.0.0] - 2025-09-XX

### Added
- Initial Raspberry Pi support
- Basic network monitoring
- Device detection and tracking
- Web-based dashboard interface

### Changed
- Ported from development environment
- Optimized for embedded deployment

---

## Version History Summary

- **8.0.0** - Interface Controls & Boot Notifications (Current)
- **7.0.14** - Multi-network & Voice Integration
- **7.0.0** - Raspberry Pi Production Release
- **6.9.0** - Mobile Enhancement Release
- **6.0.0** - Initial Pi Release

---

## Upgrade Paths

### To 8.0.0 from 7.x
```bash
cd ~/eero-dashboard
git pull
./fix-deployment-ready.sh
```

### To 8.0.0 from 6.x
```bash
# Backup existing installation
cp -r ~/.eero-dashboard ~/.eero-dashboard.backup

# Fresh installation recommended
git clone https://github.com/Drew-CodeRGV/eero-dashboard-pi.git
cd eero-dashboard-pi
sudo ./install.sh
```

---

## Breaking Changes

### Version 8.0.0
- Admin panel layout reorganized (automatic migration)
- Boot notification service requires installation
- Interface access controls change nginx configuration
- Network deletion now purges all associated data

### Version 7.0.0
- Configuration file format changed
- Service name changed to eero-dashboard.service
- New authentication flow required

---

## Deprecation Notices

### Version 8.0.0
- Legacy single-network configuration format (still supported)
- Old admin panel layout (automatically updated)

### Future Versions
- Python 3.6 support will be dropped in version 9.0.0
- Legacy authentication methods will be removed in version 9.0.0

---

## Contributors

- **Drew Lentz** - Project maintainer and primary developer
- **Community Contributors** - Bug reports, feature requests, and testing

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.