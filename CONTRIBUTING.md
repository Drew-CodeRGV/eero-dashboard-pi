# Contributing to Eero Dashboard for Raspberry Pi

Thank you for your interest in contributing! This project welcomes contributions from the community.

## 🚀 Getting Started

### Development Setup
```bash
# Clone the repository
git clone https://github.com/your-username/eero-dashboard-pi.git
cd eero-dashboard-pi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run in development mode
python dashboard.py
```

## 📋 How to Contribute

### Reporting Issues
- Use the [GitHub Issues](https://github.com/your-username/eero-dashboard-pi/issues) page
- Include detailed steps to reproduce the problem
- Provide system information (Pi model, OS version, Python version)
- Include relevant log files from `~/.eero-dashboard/dashboard.log`

### Suggesting Features
- Open a [GitHub Discussion](https://github.com/your-username/eero-dashboard-pi/discussions)
- Describe the feature and its use case
- Consider implementation complexity and Pi resource constraints

### Code Contributions

#### Pull Request Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test on actual Raspberry Pi hardware if possible
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

#### Code Standards
- Follow PEP 8 for Python code
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small
- Test on Raspberry Pi when possible

#### Testing Guidelines
- Test on multiple Pi models if available (Pi 3B+, Pi 4)
- Verify memory usage stays reasonable (<200MB)
- Check that features work with slow SD cards
- Test network connectivity edge cases
- Verify systemd service integration

## 🎯 Development Guidelines

### Performance Considerations
- **Memory Usage**: Keep RAM usage minimal for older Pi models
- **CPU Efficiency**: Avoid blocking operations in main thread
- **Storage**: Be mindful of SD card wear and space usage
- **Network**: Minimize API calls and handle timeouts gracefully

### Code Organization
- **Frontend**: All UI code in `index.html`
- **Backend**: Flask routes and logic in `dashboard.py`
- **Configuration**: JSON-based config in user home directory
- **Documentation**: Keep README and inline docs updated

### Pi-Specific Considerations
- **ARM Compatibility**: Ensure all dependencies work on ARM
- **Resource Constraints**: Test on Pi 3B+ (minimum supported model)
- **Systemd Integration**: Maintain service file compatibility
- **Auto-start**: Ensure dashboard starts reliably on boot

## 🔧 Development Environment

### Recommended Setup
- **Hardware**: Raspberry Pi 4 (4GB+ RAM recommended for development)
- **OS**: Raspberry Pi OS (64-bit preferred)
- **Editor**: VS Code with Python extension
- **Testing**: Physical Pi hardware for final testing

### Useful Commands
```bash
# Check service status
sudo systemctl status eero-dashboard

# View live logs
sudo journalctl -u eero-dashboard -f

# Test memory usage
free -h
ps aux | grep python

# Monitor CPU usage
htop

# Check disk usage
df -h
```

## 📚 Documentation

### Code Documentation
- Add docstrings to all functions and classes
- Include parameter types and return values
- Document any Pi-specific considerations
- Update README for new features

### User Documentation
- Update installation instructions if needed
- Add troubleshooting steps for new features
- Include screenshots for UI changes
- Update configuration examples

## 🐛 Debugging

### Common Issues
- **Service won't start**: Check systemd logs
- **High memory usage**: Profile with memory_profiler
- **Slow performance**: Check SD card speed and CPU usage
- **Network issues**: Test API connectivity manually

### Debugging Tools
```bash
# Python memory profiling
pip install memory_profiler
python -m memory_profiler dashboard.py

# Network debugging
curl -v http://localhost:5000/api/dashboard

# System monitoring
iostat -x 1  # Disk I/O
vmstat 1     # Memory and CPU
```

## 🎨 UI/UX Guidelines

### Design Principles
- **Mobile First**: Design for small screens first
- **Touch Friendly**: Large touch targets (44px minimum)
- **High Contrast**: Ensure readability in various lighting
- **Performance**: Minimize JavaScript and CSS complexity

### Eero Brand Guidelines
- Use official Eero colors (midnight blue, green, amber, red)
- Maintain professional, clean appearance
- Follow existing spacing and typography patterns
- Keep animations minimal for performance

## 🚀 Release Process

### Version Numbering
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Increment PATCH for bug fixes
- Increment MINOR for new features
- Increment MAJOR for breaking changes

### Release Checklist
- [ ] Test on multiple Pi models
- [ ] Update version numbers
- [ ] Update CHANGELOG.md
- [ ] Create release notes
- [ ] Tag release in git
- [ ] Update installation scripts

## 📞 Getting Help

### Community Support
- **Discussions**: [GitHub Discussions](https://github.com/your-username/eero-dashboard-pi/discussions)
- **Issues**: [GitHub Issues](https://github.com/your-username/eero-dashboard-pi/issues)
- **Documentation**: [Project Wiki](https://github.com/your-username/eero-dashboard-pi/wiki)

### Maintainer Contact
- Open an issue for bugs or feature requests
- Use discussions for questions and ideas
- Email for security-related issues only

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- GitHub contributors page

Thank you for helping make this project better! 🎉