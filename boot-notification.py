#!/usr/bin/env python3
"""
Boot Notification Service for Eero Dashboard
Sends email notification with IP addresses on system startup
"""
import os
import sys
import json
import time
import logging
from pathlib import Path

# Add the dashboard directory to Python path
dashboard_dir = Path(__file__).parent
sys.path.insert(0, str(dashboard_dir))

# Import the send_boot_notification function from dashboard.py
try:
    from dashboard import send_boot_notification, LOCAL_DIR, load_config
except ImportError as e:
    print(f"Error importing dashboard functions: {e}")
    sys.exit(1)

def setup_logging():
    """Setup logging for boot notification service"""
    log_file = LOCAL_DIR / 'boot-notification.log'
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    
    # Rotate logs to prevent SD card filling up
    if log_file.exists() and log_file.stat().st_size > 5 * 1024 * 1024:  # 5MB
        backup_file = LOCAL_DIR / f'boot-notification.log.{int(time.time())}'
        log_file.rename(backup_file)
        # Keep only last 2 backup files
        backup_files = sorted(LOCAL_DIR.glob('boot-notification.log.*'))
        for old_backup in backup_files[:-2]:
            old_backup.unlink()

def wait_for_network(max_wait=60):
    """Wait for network connectivity before sending notification"""
    import subprocess
    
    logging.info("Waiting for network connectivity...")
    
    for attempt in range(max_wait):
        try:
            # Try to ping Google DNS
            result = subprocess.run(
                ['ping', '-c', '1', '-W', '2', '8.8.8.8'],
                capture_output=True,
                timeout=5
            )
            
            if result.returncode == 0:
                logging.info(f"Network connectivity established after {attempt + 1} seconds")
                return True
                
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
            pass
        
        time.sleep(1)
    
    logging.warning(f"Network connectivity not established after {max_wait} seconds")
    return False

def main():
    """Main function for boot notification service"""
    try:
        # Ensure local directory exists
        LOCAL_DIR.mkdir(exist_ok=True)
        
        # Setup logging
        setup_logging()
        
        logging.info("Boot notification service starting...")
        
        # Check if boot notifications are enabled
        config = load_config()
        boot_config = config.get('boot_notification', {})
        
        if not boot_config.get('enabled', True):
            logging.info("Boot notifications are disabled, exiting")
            return True
        
        # Wait a bit for system to fully boot
        logging.info("Waiting for system to fully boot...")
        time.sleep(10)
        
        # Wait for network connectivity
        if not wait_for_network():
            logging.error("Failed to establish network connectivity, cannot send notification")
            return False
        
        # Send boot notification
        logging.info("Sending boot notification...")
        send_boot_notification(test_mode=False)
        
        logging.info("Boot notification sent successfully")
        return True
        
    except Exception as e:
        logging.error(f"Boot notification service error: {str(e)}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)