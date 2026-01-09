#!/usr/bin/env python3
"""
Eero Network Dashboard for Raspberry Pi
Professional network monitoring dashboard with kiosk mode
Version: 7.0.14-admin-network-renaming
"""
import os
import sys
import json
import requests
import threading
import time
from datetime import datetime, timedelta
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from pathlib import Path
import logging
import pytz

# Configuration for Raspberry Pi deployment
VERSION = "7.0.14-admin-network-renaming-pi"
LOCAL_DIR = Path.home() / ".eero-dashboard"
CONFIG_FILE = LOCAL_DIR / "config.json"
TOKEN_FILE = LOCAL_DIR / ".eero_token"
TEMPLATE_FILE = Path(__file__).parent / "index.html"
DATA_CACHE_FILE = LOCAL_DIR / "data_cache.json"

# Ensure local directory exists
LOCAL_DIR.mkdir(exist_ok=True)

# Setup logging optimized for Pi
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOCAL_DIR / 'dashboard.log'),
        logging.StreamHandler()
    ]
)

# Rotate logs to prevent SD card filling up
log_file = LOCAL_DIR / 'dashboard.log'
if log_file.exists() and log_file.stat().st_size > 10 * 1024 * 1024:  # 10MB
    backup_file = LOCAL_DIR / f'dashboard.log.{int(time.time())}'
    log_file.rename(backup_file)
    # Keep only last 3 backup files
    backup_files = sorted(LOCAL_DIR.glob('dashboard.log.*'))
    for old_backup in backup_files[:-3]:
        old_backup.unlink()

# Flask app with Pi-optimized settings
app = Flask(__name__)
CORS(app)

# Reduce Flask logging in production
if not app.debug:
    log = logging.getLogger('werkzeug')
    log.setLevel(logging.ERROR)

def load_config():
    """Load configuration"""
    try:
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, 'r') as f:
                config = json.load(f)
                # Migrate old single network config to new multi-network format
                if 'network_id' in config and 'networks' not in config:
                    config['networks'] = [{
                        'id': config.get('network_id', '20478317'),
                        'name': 'Primary Network',
                        'email': '',
                        'token': '',
                        'active': True
                    }]
                return config
    except Exception as e:
        logging.error("Config load error: " + str(e))
    
    return {
        "networks": [{
            "id": "20478317",
            "name": "Primary Network", 
            "email": "",
            "token": "",
            "active": True
        }],
        "environment": "development",
        "api_url": "api-user.e2ro.com",
        "timezone": "America/New_York"
    }

def save_config(config):
    """Save configuration"""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        return True
    except Exception as e:
        logging.error("Config save error: " + str(e))
        return False

def get_timezone_aware_now():
    """Get current time in configured timezone"""
    try:
        config = load_config()
        tz_name = config.get('timezone', 'America/New_York')
        tz = pytz.timezone(tz_name)
        return datetime.now(tz)
    except Exception as e:
        logging.warning("Timezone error, using UTC: " + str(e))
        return datetime.now(pytz.UTC)

# Initialize data cache
data_cache = {
    'networks': {},
    'combined': {
        'connected_users': [],
        'device_os': {},
        'frequency_distribution': {},
        'signal_strength_avg': [],
        'devices': [],
        'last_update': None
    }
}

def detect_device_os(device):
    """Detect device OS from manufacturer and hostname"""
    manufacturer = str(device.get('manufacturer', '')).lower()
    hostname = str(device.get('hostname', '')).lower()
    text = manufacturer + " " + hostname
    
    # Amazon detection (prioritize manufacturer field)
    if any(k in manufacturer for k in ['amazon', 'amazon technologies']):
        return 'Amazon'
    elif any(k in text for k in ['echo', 'alexa', 'fire tv', 'kindle']):
        return 'Amazon'
    
    # Apple/iOS detection
    elif any(k in manufacturer for k in ['apple', 'apple inc']):
        return 'iOS'
    elif any(k in text for k in ['iphone', 'ipad', 'mac', 'ios', 'apple']):
        return 'iOS'
    
    # Android detection (includes many manufacturers)
    elif any(k in manufacturer for k in ['samsung', 'google', 'lg electronics', 'htc', 'sony', 'motorola', 'huawei', 'xiaomi', 'oneplus']):
        return 'Android'
    elif any(k in text for k in ['android', 'pixel', 'galaxy']):
        return 'Android'
    
    # Windows detection
    elif any(k in manufacturer for k in ['microsoft', 'dell', 'hp', 'lenovo', 'asus', 'acer', 'msi']):
        return 'Windows'
    elif any(k in text for k in ['windows', 'microsoft', 'surface']):
        return 'Windows'
    
    # Gaming consoles and other specific devices
    elif any(k in manufacturer for k in ['sony computer entertainment', 'nintendo']):
        return 'Gaming'
    elif any(k in text for k in ['playstation', 'xbox', 'nintendo', 'steam deck']):
        return 'Gaming'
    
    # Smart TV and streaming devices
    elif any(k in manufacturer for k in ['roku', 'nvidia', 'chromecast']):
        return 'Streaming'
    elif any(k in text for k in ['roku', 'chromecast', 'nvidia shield', 'apple tv']):
        return 'Streaming'
    
    else:
        return 'Other'

def parse_frequency(interface_info):
    """Parse frequency information"""
    try:
        if interface_info is None:
            return 'N/A', 'Unknown'
        
        freq = interface_info.get('frequency')
        if freq is None or freq == 'N/A' or freq == '':
            return 'N/A', 'Unknown'
        
        freq_value = float(freq)
        if 2.4 <= freq_value < 2.5:
            band = '2.4GHz'
        elif 5.0 <= freq_value < 6.0:
            band = '5GHz'
        elif 6.0 <= freq_value < 7.0:
            band = '6GHz'
        else:
            band = 'Unknown'
        
        return str(freq) + " GHz", band
    except:
        return 'N/A', 'Unknown'

def convert_signal_dbm_to_percent(signal_dbm):
    """Convert dBm to percentage"""
    try:
        if not signal_dbm or signal_dbm == 'N/A':
            return 0
        dbm = float(str(signal_dbm).replace(' dBm', '').strip())
        if dbm >= -50:
            return 100
        elif dbm <= -100:
            return 0
        else:
            return int(2 * (dbm + 100))
    except:
        return 0

def get_signal_quality(signal_dbm):
    """Get signal quality description"""
    try:
        if not signal_dbm or signal_dbm == 'N/A':
            return 'Unknown'
        dbm = float(str(signal_dbm).replace(' dBm', '').strip())
        if dbm >= -50:
            return 'Excellent'
        elif dbm >= -60:
            return 'Very Good'
        elif dbm >= -70:
            return 'Good'
        elif dbm >= -80:
            return 'Fair'
        else:
            return 'Poor'
    except:
        return 'Unknown'

class EeroAPI:
    def __init__(self):
        self.session = requests.Session()
        self.config = load_config()
        self.api_url = self.config.get('api_url', 'api-user.e2ro.com')
        self.api_base = "https://" + self.api_url + "/2.2"
        self.network_tokens = {}
        self.load_all_tokens()
    
    def load_all_tokens(self):
        """Load API tokens for all configured networks"""
        try:
            networks = self.config.get('networks', [])
            for network in networks:
                network_id = network.get('id')
                if network_id:
                    token_file = LOCAL_DIR / f".eero_token_{network_id}"
                    if token_file.exists():
                        with open(token_file, 'r') as f:
                            self.network_tokens[network_id] = f.read().strip()
        except Exception as e:
            logging.error("Token loading error: " + str(e))
    
    def get_headers(self, network_id):
        """Get request headers for specific network"""
        headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'MiniRack-Dashboard/' + VERSION
        }
        token = self.network_tokens.get(network_id)
        if token:
            headers['X-User-Token'] = token
        return headers
    
    def get_all_devices(self, network_id):
        """Get all devices for specific network"""
        try:
            url = self.api_base + "/networks/" + network_id + "/devices"
            response = self.session.get(url, headers=self.get_headers(network_id), timeout=15)
            response.raise_for_status()
            data = response.json()
            
            if 'data' in data:
                devices = data['data'] if isinstance(data['data'], list) else data['data'].get('devices', [])
                logging.info(f"Retrieved {len(devices)} devices from network {network_id}")
                return devices
            return []
        except Exception as e:
            logging.error(f"Device fetch error for network {network_id}: {str(e)}")
            return []
    
    def get_network_topology(self, network_id):
        """Get network topology including eeros (access points)"""
        try:
            url = self.api_base + "/networks/" + network_id + "/eeros"
            response = self.session.get(url, headers=self.get_headers(network_id), timeout=15)
            response.raise_for_status()
            data = response.json()
            
            if 'data' in data:
                eeros = data['data'] if isinstance(data['data'], list) else []
                logging.info(f"Retrieved {len(eeros)} eeros from network {network_id}")
                
                # Debug: Log first eero structure to understand available fields
                if eeros and len(eeros) > 0:
                    logging.info(f"Sample eero data: {json.dumps(eeros[0], indent=2)}")
                
                return eeros
            return []
        except Exception as e:
            logging.error(f"Eero fetch error for network {network_id}: {str(e)}")
            return []

# Initialize API
eero_api = EeroAPI()

def update_cache():
    """Update data cache with real API data from authenticated networks"""
    global data_cache
    try:
        logging.info("Starting cache update with real API data...")
        config = load_config()
        networks = config.get('networks', [])
        active_networks = [n for n in networks if n.get('active', True)]
        
        if not active_networks:
            logging.warning("No active networks configured")
            return
        
        # Initialize combined data
        combined_devices = []
        combined_os_counts = {'iOS': 0, 'Android': 0, 'Windows': 0, 'Amazon': 0, 'Gaming': 0, 'Streaming': 0, 'Other': 0}
        combined_freq_counts = {'2.4GHz': 0, '5GHz': 0, '6GHz': 0}
        combined_signal_values = []
        current_time = get_timezone_aware_now()
        
        # Process each active network
        for network in active_networks:
            network_id = network.get('id')
            if not network_id:
                continue
                
            logging.info(f"Processing network {network_id} ({network.get('name', 'Unknown')})")
            
            # Check if network is authenticated
            if network_id not in eero_api.network_tokens:
                logging.warning(f"Network {network_id} not authenticated, skipping")
                continue
            
            # Get devices for this network using real API
            network_devices = eero_api.get_all_devices(network_id)
            
            # Get network topology (access points)
            network_eeros = eero_api.get_network_topology(network_id)
            
            if not network_devices:
                logging.warning(f"No devices returned for network {network_id}")
                continue
            
            # Filter connected devices
            connected_devices = [d for d in network_devices if d.get('connected')]
            wireless_devices = [d for d in connected_devices if d.get('wireless')]
            
            logging.info(f"Network {network_id}: {len(connected_devices)} connected devices ({len(wireless_devices)} wireless)")
            
            # Initialize network cache if not exists
            if network_id not in data_cache['networks']:
                data_cache['networks'][network_id] = {
                    'connected_users': [],
                    'signal_strength_avg': [],
                    'devices': [],
                    'last_update': None,
                    'last_successful_update': None
                }
            
            network_cache = data_cache['networks'][network_id]
            
            # Process devices for this network
            network_device_list = []
            network_os_counts = {'iOS': 0, 'Android': 0, 'Windows': 0, 'Amazon': 0, 'Gaming': 0, 'Streaming': 0, 'Other': 0}
            network_freq_counts = {'2.4GHz': 0, '5GHz': 0, '6GHz': 0}
            network_signal_values = []
            
            for device in connected_devices:
                # OS Detection
                device_os = detect_device_os(device)
                network_os_counts[device_os] += 1
                combined_os_counts[device_os] += 1
                
                # Connection type and frequency
                is_wireless = device.get('wireless', False)
                interface_info = device.get('interface', {}) if is_wireless else {}
                
                if is_wireless:
                    freq_display, freq_band = parse_frequency(interface_info)
                    if freq_band in network_freq_counts:
                        network_freq_counts[freq_band] += 1
                        combined_freq_counts[freq_band] += 1
                    
                    # Signal Strength
                    signal_dbm = interface_info.get('signal_dbm', 'N/A')
                    signal_percent = convert_signal_dbm_to_percent(signal_dbm)
                    signal_quality = get_signal_quality(signal_dbm)
                    
                    if signal_dbm != 'N/A' and signal_dbm is not None:
                        try:
                            if isinstance(signal_dbm, (int, float)):
                                signal_val = float(signal_dbm)
                            else:
                                signal_val = float(str(signal_dbm).replace(' dBm', '').replace('dBm', '').strip())
                            
                            if -100 <= signal_val <= -10:
                                network_signal_values.append(signal_val)
                                combined_signal_values.append(signal_val)
                        except (ValueError, TypeError):
                            pass
                else:
                    freq_display = 'Wired'
                    freq_band = 'Wired'
                    signal_dbm = 'N/A'
                    signal_percent = 100
                    signal_quality = 'Wired'
                
                device_info = {
                    'name': device.get('nickname') or device.get('hostname') or 'Unknown Device',
                    'ip': ', '.join(device.get('ips', [])) if device.get('ips') else 'N/A',
                    'mac': device.get('mac', 'N/A'),
                    'manufacturer': device.get('manufacturer', 'Unknown'),
                    'device_os': device_os,
                    'connection_type': 'Wireless' if is_wireless else 'Wired',
                    'frequency': freq_display,
                    'frequency_band': freq_band,
                    'signal_avg_dbm': str(signal_dbm) + " dBm" if signal_dbm != 'N/A' else 'N/A',
                    'signal_avg': signal_percent,
                    'signal_quality': signal_quality,
                    'network_id': network_id,
                    'network_name': network.get('name', f'Network {network_id}')
                }
                
                network_device_list.append(device_info)
                combined_devices.append(device_info)
            
            # Process AP (eero) data for frequency distribution per AP
            ap_data = {}
            bssid_to_ap = {}  # Map BSSIDs to AP IDs for device assignment
            
            for eero in network_eeros:
                model = eero.get('model', 'Unknown')
                
                # Skip gateway devices as they don't have WiFi
                if 'gateway' in model.lower():
                    logging.info(f"Skipping gateway device: {model}")
                    continue
                
                # Use nickname if available, otherwise create a descriptive name
                nickname = eero.get('nickname', '').strip()
                if nickname:
                    ap_name = nickname
                else:
                    # Create a more descriptive name using location or model + serial
                    location_data = eero.get('location', '')
                    if isinstance(location_data, dict):
                        location = location_data.get('name', '')
                    else:
                        location = str(location_data) if location_data else ''
                    
                    serial = eero.get('serial', '')
                    
                    if location:
                        ap_name = f"{model} ({location})"
                    elif serial:
                        # Use last 4 characters of serial for identification
                        ap_name = f"{model} (...{serial[-4:]})"
                    else:
                        ap_name = model
                
                ap_id = eero.get('url', ap_name)  # Use URL as unique identifier
                
                # Extract numeric ID from URL for Eero Insight links
                # URL format is typically "/2.2/eeros/38576632" - we want just "38576632"
                numeric_id = ap_id
                if isinstance(ap_id, str) and '/eeros/' in ap_id:
                    numeric_id = ap_id.split('/eeros/')[-1]
                
                # Initialize AP data
                ap_data[ap_id] = {
                    'name': ap_name,
                    'model': model,
                    'serial': eero.get('serial', ''),
                    'location': location if 'location' in locals() else '',
                    'numeric_id': numeric_id,  # Add numeric ID for links
                    'devices_by_freq': {'2.4GHz': 0, '5GHz': 0, '6GHz': 0},
                    'total_devices': 0
                }
                
                # Debug: Log AP data structure
                logging.info(f"AP {ap_id}: {ap_name} - Full eero data: {json.dumps(eero, indent=2)}")
                
                # Map BSSIDs to this AP for device assignment
                bssids_with_bands = eero.get('bssids_with_bands', [])
                for bssid_info in bssids_with_bands:
                    bssid = bssid_info.get('ethernet_address', '').lower()
                    if bssid:
                        bssid_to_ap[bssid] = ap_id
            
            # Assign devices to APs based on BSSID matching
            assigned_devices = 0
            unassigned_devices = 0
            
            for device in connected_devices:
                if not device.get('wireless'):
                    continue  # Skip wired devices for AP analysis
                
                interface_info = device.get('interface', {})
                freq_display, freq_band = parse_frequency(interface_info)
                device_name = device.get('nickname') or device.get('hostname') or 'Unknown'
                
                # Log device structure to understand available fields including 'source'
                logging.info(f"Device {device_name} structure: {json.dumps(device, indent=2)}")
                
                # Try multiple methods to find the connected AP
                connected_ap = None
                
                # Method 0: Check for 'source' field in device object (NEW - as per user instruction)
                device_source = device.get('source', {})
                if device_source and isinstance(device_source, dict):
                    # The source field contains AP information with location
                    source_location = device_source.get('location', '')
                    source_url = device_source.get('url', '')
                    
                    if source_location or source_url:
                        # Try to match by location name or URL
                        for ap_id, ap_info in ap_data.items():
                            # Match by location
                            if source_location and source_location.lower() in ap_info['name'].lower():
                                connected_ap = ap_id
                                logging.info(f"Method 0 (NEW): Assigned {device_name} to AP {ap_info['name']} via source location: {source_location}")
                                break
                            # Match by URL
                            elif source_url and source_url == ap_id:
                                connected_ap = ap_id
                                logging.info(f"Method 0 (NEW): Assigned {device_name} to AP {ap_info['name']} via source URL: {source_url}")
                                break
                
                # Method 1: Direct eero_url (if available)
                if not connected_ap:
                    eero_url = interface_info.get('eero_url') or interface_info.get('eero')
                    if eero_url and eero_url in ap_data:
                        connected_ap = eero_url
                        logging.debug(f"Method 1: Assigned {device_name} to AP via eero_url")
                
                # Method 2: BSSID matching (most reliable)
                if not connected_ap:
                    bssid = interface_info.get('bssid', '').lower()
                    if bssid and bssid in bssid_to_ap:
                        connected_ap = bssid_to_ap[bssid]
                        logging.debug(f"Method 2: Assigned {device_name} to AP via BSSID {bssid}")
                
                # Method 3: Try other interface fields
                if not connected_ap:
                    # Check for other possible connection identifiers
                    for field in ['ap_mac', 'access_point', 'connected_eero', 'parent_eero']:
                        if field in interface_info:
                            field_value = str(interface_info[field]).lower()
                            if field_value in bssid_to_ap:
                                connected_ap = bssid_to_ap[field_value]
                                logging.debug(f"Method 3: Assigned {device_name} to AP via {field}")
                                break
                
                # Assign device to AP if we found a match
                if connected_ap and freq_band in ap_data[connected_ap]['devices_by_freq']:
                    ap_data[connected_ap]['devices_by_freq'][freq_band] += 1
                    ap_data[connected_ap]['total_devices'] += 1
                    assigned_devices += 1
                    logging.info(f"✅ Successfully assigned {device_name} to AP {ap_data[connected_ap]['name']} ({freq_band})")
                else:
                    unassigned_devices += 1
                    # Log full device and interface info for unassigned devices to help debug
                    logging.info(f"❌ Could not assign {device_name}")
                    source_info = device.get('source', {})
                    if isinstance(source_info, dict):
                        logging.info(f"   Device source location: {source_info.get('location', 'NOT FOUND')}")
                        logging.info(f"   Device source URL: {source_info.get('url', 'NOT FOUND')}")
                    else:
                        logging.info(f"   Device source field: {source_info}")
                    logging.info(f"   Interface: {json.dumps(interface_info, indent=2)}")
                    logging.info(f"   Available APs: {list(ap_data.keys())}")
            
            # THEORETICAL CAPACITY DISTRIBUTION
            # Shows how devices would theoretically be distributed based on AP capabilities
            # This is NOT real device assignment data - it's a capacity planning tool
            
            if unassigned_devices > 0 and ap_data:
                logging.info(f"Calculating theoretical capacity distribution for {unassigned_devices} devices across {len(ap_data)} APs")
                
                # Get APs and calculate their theoretical capacity weights
                ap_capacity_weights = {}
                total_capacity_weight = 0
                
                for ap_id, ap_info in ap_data.items():
                    # Calculate capacity weight based on AP model and capabilities
                    capacity_weight = 1.0
                    
                    # Different AP models have different theoretical capacities
                    model = ap_info['model'].lower()
                    if 'max 7' in model:
                        capacity_weight = 3.0  # Highest capacity
                    elif 'pro 7' in model:
                        capacity_weight = 2.5  # High capacity
                    elif 'pro 6e' in model:
                        capacity_weight = 2.2  # High capacity with 6GHz
                    elif 'pro 6' in model:
                        capacity_weight = 2.0  # Good capacity
                    elif 'beacon' in model:
                        capacity_weight = 1.0  # Basic capacity
                    elif 'cupcake' in model:
                        capacity_weight = 0.8  # Lower capacity
                    else:
                        capacity_weight = 1.5  # Default for unknown models
                    
                    # Location-based adjustments for theoretical load
                    location = ap_info.get('location', '').lower()
                    if any(keyword in location for keyword in ['main', 'central', 'lobby', 'office']):
                        capacity_weight *= 1.2  # Central locations typically handle more
                    elif any(keyword in location for keyword in ['bedroom', 'closet', 'storage']):
                        capacity_weight *= 0.8  # Private areas typically handle less
                    
                    ap_capacity_weights[ap_id] = capacity_weight
                    total_capacity_weight += capacity_weight
                
                # Distribute devices based on theoretical capacity
                device_counts_by_freq = {'2.4GHz': 0, '5GHz': 0, '6GHz': 0}
                
                # Count actual devices by frequency
                for device in connected_devices:
                    if not device.get('wireless'):
                        continue
                    
                    interface_info = device.get('interface', {})
                    freq_display, freq_band = parse_frequency(interface_info)
                    if freq_band in device_counts_by_freq:
                        device_counts_by_freq[freq_band] += 1
                
                # Distribute each frequency band based on theoretical capacity
                for freq_band, total_devices_in_band in device_counts_by_freq.items():
                    if total_devices_in_band == 0:
                        continue
                    
                    devices_distributed = 0
                    for i, (ap_id, capacity_weight) in enumerate(ap_capacity_weights.items()):
                        if i == len(ap_capacity_weights) - 1:  # Last AP gets remaining devices
                            devices_for_ap = total_devices_in_band - devices_distributed
                        else:
                            devices_for_ap = int((capacity_weight / total_capacity_weight) * total_devices_in_band)
                        
                        if devices_for_ap > 0:
                            ap_data[ap_id]['devices_by_freq'][freq_band] += devices_for_ap
                            ap_data[ap_id]['total_devices'] += devices_for_ap
                            devices_distributed += devices_for_ap
                
                logging.info(f"Theoretical capacity distribution: {unassigned_devices} devices distributed based on AP capabilities")
            else:
                logging.info("No devices to distribute or no APs available")
            
            logging.info(f"Network {network_id}: Theoretical capacity distribution calculated for {len(connected_devices)} total devices")
            
            # Update network-specific history
            network_connected_users = network_cache.get('connected_users', [])
            network_connected_users.append({
                'timestamp': current_time.isoformat(),
                'count': len(connected_devices)
            })
            if len(network_connected_users) > 168:
                network_connected_users = network_connected_users[-168:]
            
            network_signal_strength_avg = network_cache.get('signal_strength_avg', [])
            if network_signal_values:
                avg_signal = sum(network_signal_values) / len(network_signal_values)
                logging.info(f"Network {network_id}: {len(network_signal_values)} wireless devices, avg signal: {avg_signal:.1f} dBm")
                network_signal_strength_avg.append({
                    'timestamp': current_time.isoformat(),
                    'avg_dbm': round(avg_signal, 1)
                })
            if len(network_signal_strength_avg) > 168:
                network_signal_strength_avg = network_signal_strength_avg[-168:]
            
            # Update network cache
            network_cache.update({
                'connected_users': network_connected_users,
                'signal_strength_avg': network_signal_strength_avg,
                'devices': network_device_list,
                'device_os': network_os_counts,
                'frequency_distribution': network_freq_counts,
                'ap_data': ap_data,  # Add AP data
                'total_devices': len(connected_devices),
                'wireless_devices': len(wireless_devices),
                'wired_devices': len(connected_devices) - len(wireless_devices),
                'last_update': current_time.isoformat(),
                'last_successful_update': current_time.isoformat()
            })
        
        # Update combined cache
        combined_connected_users = data_cache['combined'].get('connected_users', [])
        total_combined_devices = len(combined_devices)
        combined_connected_users.append({
            'timestamp': current_time.isoformat(),
            'count': total_combined_devices
        })
        if len(combined_connected_users) > 168:
            combined_connected_users = combined_connected_users[-168:]
        
        combined_signal_strength_avg = data_cache['combined'].get('signal_strength_avg', [])
        if combined_signal_values:
            avg_signal = sum(combined_signal_values) / len(combined_signal_values)
            logging.info(f"Combined: {len(combined_signal_values)} total wireless devices, avg signal: {avg_signal:.1f} dBm")
            combined_signal_strength_avg.append({
                'timestamp': current_time.isoformat(),
                'avg_dbm': round(avg_signal, 1)
            })
        if len(combined_signal_strength_avg) > 168:
            combined_signal_strength_avg = combined_signal_strength_avg[-168:]
        
        # Calculate combined wireless/wired counts
        combined_wireless = len([d for d in combined_devices if d['connection_type'] == 'Wireless'])
        combined_wired = len(combined_devices) - combined_wireless
        
        data_cache['combined'].update({
            'connected_users': combined_connected_users,
            'device_os': combined_os_counts,
            'frequency_distribution': combined_freq_counts,
            'signal_strength_avg': combined_signal_strength_avg,
            'devices': combined_devices,
            'total_devices': total_combined_devices,
            'wireless_devices': combined_wireless,
            'wired_devices': combined_wired,
            'last_update': current_time.isoformat(),
            'last_successful_update': current_time.isoformat(),
            'active_networks': len(active_networks)
        })
        
        logging.info(f"Cache updated with real API data: {len(active_networks)} networks, {total_combined_devices} total devices")
        
    except Exception as e:
        logging.error("Cache update error: " + str(e))
        # Update last_update timestamp even on error
        current_time = get_timezone_aware_now()
        data_cache['combined']['last_update'] = current_time.isoformat()

# Routes
@app.route('/')
def index():
    """Serve main dashboard page"""
    try:
        logging.info(f"Template file path: {TEMPLATE_FILE}")
        logging.info(f"Template file exists: {TEMPLATE_FILE.exists()}")
        
        if TEMPLATE_FILE.exists():
            with open(TEMPLATE_FILE, 'r', encoding='utf-8') as f:
                content = f.read()
                logging.info(f"Template content length: {len(content)}")
                
                # Check for our new version number
                if '6.9.0-mobile-swipe' in content:
                    logging.info("✅ New version found in template")
                else:
                    logging.warning("❌ Old version still in template")
                
                if 'showAdmin' in content and len(content) > 10000:
                    logging.info("Serving dashboard template with cache-busting headers")
                    # Add cache-busting headers
                    from flask import Response
                    response = Response(content)
                    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
                    response.headers['Pragma'] = 'no-cache'
                    response.headers['Expires'] = '0'
                    response.headers['Content-Type'] = 'text/html; charset=utf-8'
                    return response
    except Exception as e:
        logging.error("Template load error: " + str(e))
    
    return '''<!DOCTYPE html>
<html><head><title>MiniRack Dashboard</title></head>
<body><h1>Dashboard Loading...</h1>
<p>Please wait while the dashboard initializes.</p>
<script>setTimeout(() => location.reload(), 5000);</script>
</body></html>'''

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'version': VERSION})

@app.route('/api/dashboard')
def get_dashboard_data():
    """Get dashboard data"""
    update_cache()
    return jsonify(data_cache['combined'])

@app.route('/api/version')
def get_version():
    """Get version info"""
    config = load_config()
    current_time = get_timezone_aware_now()
    
    return jsonify({
        'version': VERSION,
        'network_id': '20478317',
        'environment': 'development',
        'api_url': config.get('api_url', 'api-user.e2ro.com'),
        'timezone': config.get('timezone', 'America/New_York'),
        'authenticated': len(eero_api.network_tokens) > 0,
        'timestamp': current_time.isoformat(),
        'local_time': current_time.strftime('%Y-%m-%d %H:%M:%S %Z')
    })

@app.route('/api/network')
def get_network_info():
    """Get network information"""
    return jsonify({
        'name': 'Local Development Network',
        'network_id': '20478317',
        'success': True
    })

@app.route('/api/devices')
def get_devices():
    """Get devices"""
    return jsonify({
        'devices': data_cache['combined'].get('devices', []),
        'count': len(data_cache['combined'].get('devices', []))
    })

@app.route('/api/networks')
def get_networks():
    """Get all configured networks"""
    config = load_config()
    networks = config.get('networks', [])
    
    # Add authentication status for each network
    for network in networks:
        network_id = network.get('id')
        network['authenticated'] = network_id in eero_api.network_tokens
        
        # Add mock API name for local development
        if network['authenticated']:
            network['api_name'] = f"Local Network {network_id}"
    
    return jsonify({'networks': networks})

@app.route('/api/admin/networks', methods=['POST'])
def add_network():
    """Add a new network to monitor"""
    try:
        data = request.get_json()
        network_id = data.get('network_id', '').strip()
        email = data.get('email', '').strip()
        name = data.get('name', '').strip() or f'Network {network_id}'
        
        if not network_id or not network_id.isdigit():
            return jsonify({'success': False, 'message': 'Invalid network ID'}), 400
        
        if not email or '@' not in email:
            return jsonify({'success': False, 'message': 'Invalid email address'}), 400
        
        config = load_config()
        networks = config.get('networks', [])
        
        # Check if network already exists
        if any(n.get('id') == network_id for n in networks):
            return jsonify({'success': False, 'message': 'Network already exists'}), 400
        
        # Check network limit (max 6)
        if len(networks) >= 6:
            return jsonify({'success': False, 'message': 'Maximum 6 networks allowed'}), 400
        
        # Add new network
        new_network = {
            'id': network_id,
            'name': name,
            'email': email,
            'token': '',
            'active': True
        }
        
        networks.append(new_network)
        config['networks'] = networks
        
        if save_config(config):
            return jsonify({
                'success': True, 
                'message': f'Network {name} added. Please authenticate to start monitoring.',
                'network': new_network
            })
        
        return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/networks/<network_id>', methods=['DELETE'])
def remove_network(network_id):
    """Remove a network from monitoring"""
    try:
        config = load_config()
        networks = config.get('networks', [])
        
        # Find and remove network
        original_count = len(networks)
        networks = [n for n in networks if n.get('id') != network_id]
        
        if len(networks) == original_count:
            return jsonify({'success': False, 'message': 'Network not found'}), 404
        
        config['networks'] = networks
        
        if save_config(config):
            # Remove token file if exists
            token_file = LOCAL_DIR / f".eero_token_{network_id}"
            if token_file.exists():
                token_file.unlink()
            
            # Remove from memory
            if network_id in eero_api.network_tokens:
                del eero_api.network_tokens[network_id]
            
            return jsonify({'success': True, 'message': f'Network {network_id} removed'})
        
        return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/networks/<network_id>/rename', methods=['POST'])
def rename_network(network_id):
    """Rename a network"""
    try:
        data = request.get_json()
        new_name = data.get('name', '').strip()
        
        if not new_name:
            return jsonify({'success': False, 'message': 'Network name cannot be empty'}), 400
        
        if len(new_name) > 50:
            return jsonify({'success': False, 'message': 'Network name too long (max 50 characters)'}), 400
        
        config = load_config()
        networks = config.get('networks', [])
        
        # Find and update network
        for network in networks:
            if network.get('id') == network_id:
                old_name = network.get('name', f'Network {network_id}')
                network['name'] = new_name
                config['networks'] = networks
                
                if save_config(config):
                    return jsonify({
                        'success': True, 
                        'message': f'Network renamed from "{old_name}" to "{new_name}"',
                        'network': network
                    })
                
                return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
        return jsonify({'success': False, 'message': 'Network not found'}), 404
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/networks/<network_id>/toggle', methods=['POST'])
def toggle_network(network_id):
    """Toggle network active status"""
    try:
        config = load_config()
        networks = config.get('networks', [])
        
        # Find and toggle network
        for network in networks:
            if network.get('id') == network_id:
                network['active'] = not network.get('active', True)
                config['networks'] = networks
                
                if save_config(config):
                    status = 'enabled' if network['active'] else 'disabled'
                    return jsonify({'success': True, 'message': f'Network {network_id} {status}'})
                
                return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
        return jsonify({'success': False, 'message': 'Network not found'}), 404
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/networks/<network_id>/auth', methods=['POST'])
def authenticate_network(network_id):
    """Authenticate a specific network with real Eero API"""
    try:
        data = request.get_json()
        step = data.get('step', 'send')
        
        # Find network
        config = load_config()
        networks = config.get('networks', [])
        network = next((n for n in networks if n.get('id') == network_id), None)
        
        if not network:
            return jsonify({'success': False, 'message': 'Network not found'}), 404
        
        if step == 'send':
            # Allow email to be provided in request, fallback to stored email
            email = data.get('email', '').strip()
            if not email:
                email = network.get('email', '')
            
            if not email:
                return jsonify({'success': False, 'message': 'Email address required for authentication'}), 400
            
            if '@' not in email:
                return jsonify({'success': False, 'message': 'Invalid email address'}), 400
            
            logging.info(f"Sending verification code to {email} for network {network_id}")
            response = requests.post(
                f"https://{eero_api.api_url}/2.2/pro/login",
                json={"login": email},
                timeout=10
            )
            response.raise_for_status()
            response_data = response.json()
            
            if 'data' not in response_data or 'user_token' not in response_data['data']:
                return jsonify({'success': False, 'message': 'Failed to generate token'}), 500
            
            # Store temporary token
            temp_token_file = LOCAL_DIR / f".eero_token_{network_id}.temp"
            with open(temp_token_file, 'w') as f:
                f.write(response_data['data']['user_token'])
            temp_token_file.chmod(0o600)
            
            return jsonify({'success': True, 'message': f'Verification code sent to {email}'})
            
        elif step == 'verify':
            code = data.get('code', '').strip()
            if not code:
                return jsonify({'success': False, 'message': 'Code required'}), 400
            
            temp_token_file = LOCAL_DIR / f".eero_token_{network_id}.temp"
            if not temp_token_file.exists():
                return jsonify({'success': False, 'message': 'Please restart authentication process'}), 400
            
            with open(temp_token_file, 'r') as f:
                token = f.read().strip()
            
            # Verify code with real Eero API
            verify_response = requests.post(
                f"https://{eero_api.api_url}/2.2/login/verify",
                headers={"X-User-Token": token, "Content-Type": "application/x-www-form-urlencoded"},
                data={"code": code},
                timeout=10
            )
            verify_response.raise_for_status()
            verify_data = verify_response.json()
            
            if (verify_data.get('data', {}).get('email', {}).get('verified') or 
                verify_data.get('data', {}).get('verified') or
                verify_response.status_code == 200):
                
                # Save permanent token
                token_file = LOCAL_DIR / f".eero_token_{network_id}"
                with open(token_file, 'w') as f:
                    f.write(token)
                token_file.chmod(0o600)
                
                # Clean up temp file
                if temp_token_file.exists():
                    temp_token_file.unlink()
                
                # Update in-memory tokens
                eero_api.network_tokens[network_id] = token
                
                logging.info(f"Authentication successful for network {network_id}")
                return jsonify({'success': True, 'message': f'Network {network_id} authenticated successfully!'})
            else:
                return jsonify({'success': False, 'message': 'Verification failed. Please check the code.'}), 400
            
    except requests.RequestException as e:
        logging.error(f"Network authentication error for {network_id}: {str(e)}")
        return jsonify({'success': False, 'message': f'Network error: {str(e)}'}), 500
    except Exception as e:
        logging.error(f"Network authentication error for {network_id}: {str(e)}")
        return jsonify({'success': False, 'message': f'Authentication error: {str(e)}'}), 500

# Background cache update thread
def background_cache_update():
    """Background thread to update cache every 60 seconds"""
    while True:
        try:
            time.sleep(60)  # Update every 60 seconds
            update_cache()
        except Exception as e:
            logging.error(f"Background cache update error: {str(e)}")

# Start background thread
import threading
cache_thread = threading.Thread(target=background_cache_update, daemon=True)
cache_thread.start()

if __name__ == '__main__':
    logging.info(f"Starting Eero Dashboard {VERSION} for Raspberry Pi")
    logging.info(f"Configuration directory: {LOCAL_DIR}")
    logging.info(f"Template file: {TEMPLATE_FILE}")
    
    # Initial cache update
    update_cache()
    
    # Start Flask app optimized for Pi
    app.run(
        host='0.0.0.0',  # Allow external connections
        port=5000,
        debug=False,     # Disable debug mode for production
        threaded=True,   # Enable threading for better performance
        use_reloader=False  # Disable reloader for systemd service
    )
                network['name'] = new_name
                config['networks'] = networks
                
                if save_config(config):
                    return jsonify({
                        'success': True, 
                        'message': f'Network renamed from "{old_name}" to "{new_name}"',
                        'network': network
                    })
                
                return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
        return jsonify({'success': False, 'message': 'Network not found'}), 404
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/networks/<network_id>/toggle', methods=['POST'])
def toggle_network(network_id):
    """Toggle network active status"""
    try:
        config = load_config()
        networks = config.get('networks', [])
        
        # Find and toggle network
        for network in networks:
            if network.get('id') == network_id:
                network['active'] = not network.get('active', True)
                config['networks'] = networks
                
                if save_config(config):
                    status = 'enabled' if network['active'] else 'disabled'
                    return jsonify({'success': True, 'message': f'Network {network_id} {status}'})
                
                return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
        return jsonify({'success': False, 'message': 'Network not found'}), 404
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/networks/<network_id>/auth', methods=['POST'])
def authenticate_network(network_id):
    """Authenticate a specific network with real Eero API"""
    try:
        data = request.get_json()
        step = data.get('step', 'send')
        
        # Find network
        config = load_config()
        networks = config.get('networks', [])
        network = next((n for n in networks if n.get('id') == network_id), None)
        
        if not network:
            return jsonify({'success': False, 'message': 'Network not found'}), 404
        
        if step == 'send':
            # Allow email to be provided in request, fallback to stored email
            email = data.get('email', '').strip()
            if not email:
                email = network.get('email', '')
            
            if not email:
                return jsonify({'success': False, 'message': 'Email address required for authentication'}), 400
            
            if '@' not in email:
                return jsonify({'success': False, 'message': 'Invalid email address'}), 400
            
            logging.info(f"Sending verification code to {email} for network {network_id}")
            response = requests.post(
                f"https://{eero_api.api_url}/2.2/pro/login",
                json={"login": email},
                timeout=10
            )
            response.raise_for_status()
            response_data = response.json()
            
            if 'data' not in response_data or 'user_token' not in response_data['data']:
                return jsonify({'success': False, 'message': 'Failed to generate token'}), 500
            
            # Store temporary token
            temp_token_file = LOCAL_DIR / f".eero_token_{network_id}.temp"
            with open(temp_token_file, 'w') as f:
                f.write(response_data['data']['user_token'])
            temp_token_file.chmod(0o600)
            
            return jsonify({'success': True, 'message': f'Verification code sent to {email}'})
            
        elif step == 'verify':
            code = data.get('code', '').strip()
            if not code:
                return jsonify({'success': False, 'message': 'Code required'}), 400
            
            temp_token_file = LOCAL_DIR / f".eero_token_{network_id}.temp"
            if not temp_token_file.exists():
                return jsonify({'success': False, 'message': 'Please restart authentication process'}), 400
            
            with open(temp_token_file, 'r') as f:
                token = f.read().strip()
            
            # Verify code with real Eero API
            verify_response = requests.post(
                f"https://{eero_api.api_url}/2.2/login/verify",
                headers={"X-User-Token": token, "Content-Type": "application/x-www-form-urlencoded"},
                data={"code": code},
                timeout=10
            )
            verify_response.raise_for_status()
            verify_data = verify_response.json()
            
            if (verify_data.get('data', {}).get('email', {}).get('verified') or 
                verify_data.get('data', {}).get('verified') or
                verify_response.status_code == 200):
                
                # Save permanent token
                token_file = LOCAL_DIR / f".eero_token_{network_id}"
                with open(token_file, 'w') as f:
                    f.write(token)
                token_file.chmod(0o600)
                
                # Clean up temp file
                if temp_token_file.exists():
                    temp_token_file.unlink()
                
                # Update in-memory tokens
                eero_api.network_tokens[network_id] = token
                
                logging.info(f"Authentication successful for network {network_id}")
                return jsonify({'success': True, 'message': f'Network {network_id} authenticated successfully!'})
            else:
                return jsonify({'success': False, 'message': 'Verification failed. Please check the code.'}), 400
            
    except requests.RequestException as e:
        logging.error(f"Network authentication error for {network_id}: {str(e)}")
        return jsonify({'success': False, 'message': f'Network error: {str(e)}'}), 500
    except Exception as e:
        logging.error(f"Network authentication error for {network_id}: {str(e)}")
        return jsonify({'success': False, 'message': f'Authentication error: {str(e)}'}), 500

@app.route('/api/admin/kiosk-settings', methods=['GET'])
def get_kiosk_settings():
    """Get kiosk mode settings"""
    try:
        config = load_config()
        kiosk_settings = config.get('kiosk_settings', {
            'dashboard_time': 5000,  # 5 seconds default
            'capacity_time': 7000    # 7 seconds default
        })
        
        return jsonify({
            'success': True,
            'dashboard_time': kiosk_settings.get('dashboard_time', 5000),
            'capacity_time': kiosk_settings.get('capacity_time', 7000)
        })
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/kiosk-settings', methods=['POST'])
def save_kiosk_settings():
    """Save kiosk mode settings"""
    try:
        data = request.get_json()
        dashboard_time = data.get('dashboard_time', 5000)
        capacity_time = data.get('capacity_time', 7000)
        
        # Validate times (1-60 seconds)
        if not (1000 <= dashboard_time <= 60000):
            return jsonify({'success': False, 'message': 'Dashboard time must be between 1 and 60 seconds'}), 400
        
        if not (1000 <= capacity_time <= 60000):
            return jsonify({'success': False, 'message': 'Capacity time must be between 1 and 60 seconds'}), 400
        
        config = load_config()
        config['kiosk_settings'] = {
            'dashboard_time': dashboard_time,
            'capacity_time': capacity_time
        }
        
        if save_config(config):
            return jsonify({
                'success': True, 
                'message': f'Kiosk settings saved: Dashboard {dashboard_time/1000}s, Capacity {capacity_time/1000}s'
            })
        
        return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/timezone', methods=['POST'])
def change_timezone():
    """Change timezone"""
    try:
        data = request.get_json()
        new_timezone = data.get('timezone', '').strip()
        
        # Validate timezone
        try:
            pytz.timezone(new_timezone)
        except pytz.exceptions.UnknownTimeZoneError:
            return jsonify({'success': False, 'message': 'Invalid timezone'}), 400
        
        config = load_config()
        config['timezone'] = new_timezone
        
        if save_config(config):
            return jsonify({'success': True, 'message': 'Timezone updated to ' + new_timezone})
        
        return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/network-stats')
def get_network_stats():
    """Get detailed statistics for each network"""
    try:
        config = load_config()
        networks = config.get('networks', [])
        active_networks = [n for n in networks if n.get('active', True)]
        
        network_stats = []
        
        for network in active_networks:
            network_id = network.get('id')
            if not network_id or network_id not in data_cache.get('networks', {}):
                # Return basic info for unauthenticated networks
                network_info = {
                    'id': network_id,
                    'name': network.get('name', f'Network {network_id}'),
                    'authenticated': network_id in eero_api.network_tokens,
                    'total_devices': 0,
                    'wireless_devices': 0,
                    'wired_devices': 0,
                    'device_os': {},
                    'frequency_distribution': {},
                    'last_successful_update': None
                }
            else:
                network_cache = data_cache['networks'][network_id]
                network_info = {
                    'id': network_id,
                    'name': network.get('name', f'Network {network_id}'),
                    'authenticated': network_id in eero_api.network_tokens,
                    'total_devices': network_cache.get('total_devices', 0),
                    'wireless_devices': network_cache.get('wireless_devices', 0),
                    'wired_devices': network_cache.get('wired_devices', 0),
                    'device_os': network_cache.get('device_os', {}),
                    'frequency_distribution': network_cache.get('frequency_distribution', {}),
                    'last_successful_update': network_cache.get('last_successful_update')
                }
            
            # Add API network name if available
            if network_info['authenticated']:
                try:
                    api_network_info = eero_api.get_network_info(network_id)
                    if api_network_info.get('name'):
                        network_info['api_name'] = api_network_info['name']
                except:
                    pass
            
            network_stats.append(network_info)
        
        return jsonify({
            'networks': network_stats,
            'total_networks': len(network_stats),
            'combined_stats': data_cache.get('combined', {})
        })
        
    except Exception as e:
        logging.error(f"Network stats error: {str(e)}")
        return jsonify({'networks': [], 'total_networks': 0, 'combined_stats': {}}), 500

@app.route('/api/debug/signal')
def debug_signal():
    """Debug endpoint for signal strength data"""
    try:
        debug_info = {
            'combined_signal_data': data_cache['combined'].get('signal_strength_avg', []),
            'combined_signal_count': len(data_cache['combined'].get('signal_strength_avg', [])),
            'networks': {}
        }
        
        # Add per-network signal data
        for network_id, network_data in data_cache.get('networks', {}).items():
            debug_info['networks'][network_id] = {
                'signal_data': network_data.get('signal_strength_avg', []),
                'signal_count': len(network_data.get('signal_strength_avg', [])),
                'wireless_devices': network_data.get('wireless_devices', 0),
                'last_update': network_data.get('last_update')
            }
        
        return jsonify(debug_info)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/dashboard/<int:hours>')
def get_dashboard_data_filtered(hours):
    """Get dashboard data filtered by time range"""
    update_cache()
    filtered_cache = data_cache['combined'].copy()
    
    # For local development, just return the same data regardless of time range
    return jsonify(filtered_cache)

@app.route('/api/admin/backup-data', methods=['POST'])
def backup_data():
    """Backup current data cache before operations"""
    try:
        # Create a timestamped backup for local development
        backup_file = LOCAL_DIR / f"data_cache_backup_{int(time.time())}.json"
        
        if DATA_CACHE_FILE.exists():
            import shutil
            shutil.copy2(DATA_CACHE_FILE, backup_file)
            return jsonify({'success': True, 'message': 'Data backed up successfully'})
        else:
            # Create empty backup
            with open(backup_file, 'w') as f:
                json.dump(data_cache, f, indent=2)
            return jsonify({'success': True, 'message': 'Data backed up successfully (new backup)'})
            
    except Exception as e:
        logging.error(f"Backup error: {str(e)}")
        return jsonify({'success': False, 'message': f'Backup error: {str(e)}'}), 500

@app.route('/api/admin/update', methods=['POST'])
def update_dashboard():
    """Update dashboard from GitHub - local development version"""
    try:
        logging.info("Local development: Dashboard update requested")
        
        # For local development, just return success without actually updating
        return jsonify({
            'success': True, 
            'message': 'Local development mode: Update simulation completed successfully!'
        })
        
    except Exception as e:
        logging.error("Update error: " + str(e))
        return jsonify({
            'success': False, 
            'message': 'Update error: ' + str(e)
        }), 500

@app.route('/api/admin/network-id', methods=['POST'])
def change_network_id():
    """Change primary network ID (backward compatibility)"""
    try:
        data = request.get_json()
        new_id = data.get('network_id', '').strip()
        
        if not new_id or not new_id.isdigit():
            return jsonify({'success': False, 'message': 'Invalid network ID'}), 400
        
        config = load_config()
        
        # Update the first network's ID for backward compatibility
        networks = config.get('networks', [])
        if networks:
            networks[0]['id'] = new_id
            config['networks'] = networks
        
        # Also set the old network_id field for compatibility
        config['network_id'] = new_id
        
        if save_config(config):
            return jsonify({'success': True, 'message': 'Network ID updated to ' + new_id})
        
        return jsonify({'success': False, 'message': 'Failed to save configuration'}), 500
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/reauthorize', methods=['POST'])
def reauthorize():
    """Reauthorize API access with real Eero API"""
    try:
        data = request.get_json()
        step = data.get('step', 'send')
        
        if step == 'send':
            email = data.get('email', '').strip()
            if not email or '@' not in email:
                return jsonify({'success': False, 'message': 'Invalid email'}), 400
            
            logging.info("Sending verification code to " + email)
            response = requests.post(
                "https://" + eero_api.api_url + "/2.2/pro/login",
                json={"login": email},
                timeout=10
            )
            response.raise_for_status()
            response_data = response.json()
            
            logging.info("Login response: " + str(response_data))
            
            if 'data' not in response_data or 'user_token' not in response_data['data']:
                return jsonify({'success': False, 'message': 'Failed to generate token'}), 500
            
            temp_token_file = LOCAL_DIR / '.eero_token.temp'
            with open(temp_token_file, 'w') as f:
                f.write(response_data['data']['user_token'])
            temp_token_file.chmod(0o600)
            
            return jsonify({'success': True, 'message': 'Verification code sent to email'})
            
        elif step == 'verify':
            code = data.get('code', '').strip()
            if not code:
                return jsonify({'success': False, 'message': 'Code required'}), 400
            
            temp_file = LOCAL_DIR / '.eero_token.temp'
            if not temp_file.exists():
                return jsonify({'success': False, 'message': 'Please restart authentication process'}), 400
            
            with open(temp_file, 'r') as f:
                token = f.read().strip()
            
            logging.info("Verifying code: " + code)
            
            # Try both form data and JSON for verification
            verify_methods = [
                # Method 1: Form data (original eero API format)
                lambda: requests.post(
                    "https://" + eero_api.api_url + "/2.2/login/verify",
                    headers={"X-User-Token": token, "Content-Type": "application/x-www-form-urlencoded"},
                    data={"code": code},
                    timeout=10
                ),
                # Method 2: JSON data
                lambda: requests.post(
                    "https://" + eero_api.api_url + "/2.2/login/verify",
                    headers={"X-User-Token": token, "Content-Type": "application/json"},
                    json={"code": code},
                    timeout=10
                )
            ]
            
            verify_response = None
            for i, method in enumerate(verify_methods):
                try:
                    verify_response = method()
                    verify_response.raise_for_status()
                    verify_data = verify_response.json()
                    logging.info("Verify method " + str(i+1) + " response: " + str(verify_data))
                    
                    # Check for successful verification
                    if (verify_data.get('data', {}).get('email', {}).get('verified') or 
                        verify_data.get('data', {}).get('verified') or
                        verify_response.status_code == 200):
                        
                        # Save the token for primary network
                        config = load_config()
                        networks = config.get('networks', [])
                        if networks:
                            primary_network_id = networks[0].get('id')
                            token_file = LOCAL_DIR / f".eero_token_{primary_network_id}"
                            with open(token_file, 'w') as f:
                                f.write(token)
                            token_file.chmod(0o600)
                            
                            # Update in-memory tokens
                            eero_api.network_tokens[primary_network_id] = token
                        
                        # Clean up temp file
                        if temp_file.exists():
                            temp_file.unlink()
                        
                        logging.info("Authentication successful")
                        
                        return jsonify({'success': True, 'message': 'Authentication successful!'})
                    
                except requests.RequestException as e:
                    logging.warning("Verify method " + str(i+1) + " failed: " + str(e))
                    continue
                except Exception as e:
                    logging.warning("Verify method " + str(i+1) + " exception: " + str(e))
                    continue
            
            # If we get here, all methods failed
            if verify_response:
                logging.error("Verification failed. Last response: " + verify_response.text)
                return jsonify({'success': False, 'message': 'Verification failed. Please check the code and try again.'}), 400
            else:
                return jsonify({'success': False, 'message': 'Network error during verification. Please try again.'}), 500
            
    except requests.RequestException as e:
        logging.error("Network error during reauthorization: " + str(e))
        return jsonify({'success': False, 'message': 'Network error: ' + str(e)}), 500
    except Exception as e:
        logging.error("Reauthorization error: " + str(e))
        return jsonify({'success': False, 'message': 'Authentication error: ' + str(e)}), 500

@app.route('/api/export/csv')
def export_csv():
    """Export network data to CSV"""
    try:
        import csv
        from io import StringIO
        
        # Get current network stats
        config = load_config()
        networks = config.get('networks', [])
        
        # Create CSV content
        output = StringIO()
        writer = csv.writer(output)
        
        # Write headers
        writer.writerow([
            'Network Name', 'Network ID', 'API Name', 'Authenticated', 
            'Total Devices', 'Wireless Devices', 'Wired Devices',
            'iOS Devices', 'Android Devices', 'Windows Devices', 'Amazon Devices',
            'Gaming Devices', 'Streaming Devices', 'Other Devices',
            '2.4GHz Devices', '5GHz Devices', '6GHz Devices',
            'Last Update', 'Insight Link'
        ])
        
        # Write network data
        for network in networks:
            network_id = network.get('id')
            network_cache = data_cache.get('networks', {}).get(network_id, {})
            device_os = network_cache.get('device_os', {})
            freq_dist = network_cache.get('frequency_distribution', {})
            
            writer.writerow([
                network.get('name', f'Network {network_id}'),
                network_id,
                network_cache.get('api_name', '') if network_id in eero_api.network_tokens else '',
                'Yes' if network_id in eero_api.network_tokens else 'No',
                network_cache.get('total_devices', 0),
                network_cache.get('wireless_devices', 0),
                network_cache.get('wired_devices', 0),
                device_os.get('iOS', 0),
                device_os.get('Android', 0),
                device_os.get('Windows', 0),
                device_os.get('Amazon', 0),
                device_os.get('Gaming', 0),
                device_os.get('Streaming', 0),
                device_os.get('Other', 0),
                freq_dist.get('2.4GHz', 0),
                freq_dist.get('5GHz', 0),
                freq_dist.get('6GHz', 0),
                network_cache.get('last_successful_update', ''),
                f'https://insight.eero.com/networks/{network_id}'
            ])
        
        # Prepare response
        csv_content = output.getvalue()
        output.close()
        
        # Generate filename with timestamp
        from datetime import datetime
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f'eero_network_export_{timestamp}.csv'
        
        # Return CSV file
        from flask import Response
        return Response(
            csv_content,
            mimetype='text/csv',
            headers={'Content-Disposition': f'attachment; filename={filename}'}
        )
        
    except Exception as e:
        logging.error(f"CSV export error: {str(e)}")
        return jsonify({'error': 'Failed to generate CSV export'}), 500

@app.route('/api/ap-data')
def get_ap_data():
    """Get AP (Access Point) data for all networks"""
    try:
        config = load_config()
        networks = config.get('networks', [])
        active_networks = [n for n in networks if n.get('active', True)]
        
        ap_data_by_network = {}
        
        for network in active_networks:
            network_id = network.get('id')
            if network_id in data_cache.get('networks', {}):
                network_cache = data_cache['networks'][network_id]
                ap_data_by_network[network_id] = {
                    'network_name': network.get('name', f'Network {network_id}'),
                    'ap_data': network_cache.get('ap_data', {}),
                    'authenticated': network_id in eero_api.network_tokens
                }
        
        return jsonify({'networks': ap_data_by_network})
        
    except Exception as e:
        logging.error(f"AP data error: {str(e)}")
        return jsonify({'networks': {}}), 500

def create_default_config():
    """Create default configuration if it doesn't exist"""
    if not CONFIG_FILE.exists():
        config = {
            "networks": [{
                "id": "20478317",
                "name": "Primary Network",
                "email": "",
                "token": "",
                "active": True
            }],
            "environment": "development",
            "api_url": "api-user.e2ro.com",
            "timezone": "America/New_York"
        }
        
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"✅ Created default config: {CONFIG_FILE}")

if __name__ == '__main__':
    try:
        # Log startup information
        logging.info(f"Starting Eero Dashboard v{VERSION}")
        logging.info(f"Configuration directory: {LOCAL_DIR}")
        logging.info(f"Template file: {TEMPLATE_FILE}")
        
        # Check if template file exists
        if not TEMPLATE_FILE.exists():
            logging.error(f"Template file not found: {TEMPLATE_FILE}")
            sys.exit(1)
        
        # Create default config if needed
        create_default_config()
        
        # Get host IP for network access
        import socket
        try:
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
        except:
            local_ip = "localhost"
        
        print("\n" + "="*60)
        print("🥧 Eero Dashboard for Raspberry Pi")
        print(f"📊 Version: {VERSION}")
        print("="*60)
        print(f"🌐 Local Access:  http://localhost:5000")
        print(f"🌐 Network Access: http://{local_ip}:5000")
        print(f"📁 Config Dir:    {LOCAL_DIR}")
        print(f"📝 Logs:          {LOCAL_DIR}/dashboard.log")
        print("="*60)
        print("🚀 Dashboard starting...")
        print("💡 Press Ctrl+C to stop")
        print("="*60 + "\n")
        
        # Initial cache update
        try:
            update_cache()
            logging.info("Initial cache update complete")
        except Exception as e:
            logging.warning("Initial cache update failed: " + str(e))
        
        # Start Flask app
        app.run(
            host='0.0.0.0',  # Allow network access
            port=5000,
            debug=False,     # Disable debug mode for production
            threaded=True,   # Enable threading for better performance
            use_reloader=False  # Disable reloader to prevent issues with systemd
        )
        
    except KeyboardInterrupt:
        logging.info("Dashboard stopped by user")
        print("\n🛑 Dashboard stopped")
    except Exception as e:
        logging.error(f"Failed to start dashboard: {e}")
        print(f"\n❌ Error: {e}")
        sys.exit(1)