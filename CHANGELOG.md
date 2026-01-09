# Changelog

All notable changes to the Eero Dashboard for Raspberry Pi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.0.14] - 2026-01-08

### Added
- **Initial Raspberry Pi Release**: Complete dashboard optimized for Pi deployment
- **Multi-Network Support**: Monitor up to 6 Eero networks simultaneously
- **Professional UI**: Official Eero brand colors and enterprise-grade design
- **AP Capacity Visualization**: Real-time device distribution across access points
- **Kiosk Mode**: Automatic switching between dashboard and capacity views
- **Network Management**: Inline renaming and authentication management
- **Systemd Integration**: Automatic startup and service management
- **Log Rotation**: Prevents SD card filling with automatic log cleanup
- **Security Features**: Secure token storage and network access controls

### Features
- **Real-time Monitoring**: Live device counts, OS distribution, frequency analysis
- **Color-coded APs**: Visual indication of AP load using Eero brand colors
- **Responsive Design**: Optimized for all screen sizes from mobile to desktop
- **Background Updates**: Non-blocking data refresh every 60 seconds
- **Data Caching**: Seamless transitions with pre-loaded data
- **Timezone Support**: Configurable timezone with automatic DST handling
- **Health Monitoring**: Built-in health checks and error recovery

### Technical
- **Python 3.7+ Support**: Compatible with all modern Pi OS versions
- **Flask Web Framework**: Lightweight and efficient web server
- **Real Eero API Integration**: Direct connection to official Eero services
- **SQLite-free Design**: JSON-based configuration for simplicity
- **Memory Optimized**: Efficient resource usage for Pi hardware
- **Thread-safe Operations**: Concurrent request handling

### Installation
- **Automated Installer**: One-command installation script
- **Manual Setup**: Step-by-step setup script for advanced users
- **Service Management**: Complete systemd service integration
- **Firewall Configuration**: Optional UFW firewall setup
- **Desktop Integration**: Automatic desktop shortcut creation

### Documentation
- **Comprehensive README**: Detailed installation and usage instructions
- **Troubleshooting Guide**: Common issues and solutions
- **API Documentation**: Complete endpoint reference
- **Configuration Guide**: All settings and options explained
- **Contributing Guidelines**: How to contribute to the project

## [Unreleased]

### Planned Features
- **HTTPS Support**: SSL/TLS encryption for secure access
- **User Authentication**: Optional login system for multi-user environments
- **Email Alerts**: Notification system for network issues
- **Historical Data**: Long-term storage and trending
- **Mobile App**: Companion mobile application
- **Docker Support**: Containerized deployment option
- **Backup/Restore**: Configuration and data backup system
- **Plugin System**: Extensible architecture for custom features

---

## Version History

This is the initial release of the Raspberry Pi version, based on the mature web dashboard that has been in development since 2024. The Pi version includes all the latest features and optimizations specifically tailored for Raspberry Pi hardware and deployment scenarios.

### Previous Development (Web Version)
- v6.x: Multi-network support and admin panel
- v5.x: AP capacity visualization
- v4.x: Kiosk mode implementation  
- v3.x: Network renaming and management
- v2.x: Improved UI and Eero branding
- v1.x: Initial dashboard development