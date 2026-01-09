#!/usr/bin/env python3
"""
Simple test script to verify Eero Dashboard installation
"""

import sys
import subprocess
import importlib
import requests
import time
from pathlib import Path

def test_python_version():
    """Test Python version compatibility"""
    print("Testing Python version...")
    version = sys.version_info
    if version.major == 3 and version.minor >= 7:
        print(f"✅ Python {version.major}.{version.minor}.{version.micro} - Compatible")
        return True
    else:
        print(f"❌ Python {version.major}.{version.minor}.{version.micro} - Requires Python 3.7+")
        return False

def test_dependencies():
    """Test required Python packages"""
    print("\nTesting Python dependencies...")
    required_packages = ['flask', 'requests', 'pytz']
    all_good = True
    
    for package in required_packages:
        try:
            importlib.import_module(package)
            print(f"✅ {package} - Available")
        except ImportError:
            print(f"❌ {package} - Missing")
            all_good = False
    
    return all_good

def test_configuration():
    """Test configuration directory and files"""
    print("\nTesting configuration...")
    config_dir = Path.home() / ".eero-dashboard"
    
    if config_dir.exists():
        print(f"✅ Configuration directory exists: {config_dir}")
    else:
        print(f"⚠️  Configuration directory missing: {config_dir}")
        print("   This will be created on first run")
    
    return True

def test_service():
    """Test if systemd service is installed and running"""
    print("\nTesting systemd service...")
    
    try:
        # Check if service file exists
        result = subprocess.run(['systemctl', 'status', 'eero-dashboard'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            if 'active (running)' in result.stdout:
                print("✅ Service is running")
                return True
            else:
                print("⚠️  Service exists but not running")
                print("   Try: sudo systemctl start eero-dashboard")
                return False
        else:
            print("❌ Service not found")
            print("   Run setup.sh to install the service")
            return False
            
    except FileNotFoundError:
        print("❌ systemctl not available (not running on systemd)")
        return False

def test_web_server():
    """Test if web server is responding"""
    print("\nTesting web server...")
    
    try:
        response = requests.get('http://localhost:5000/health', timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Web server responding - Version: {data.get('version', 'Unknown')}")
            return True
        else:
            print(f"❌ Web server error - Status: {response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to web server on port 5000")
        print("   Make sure the service is running")
        return False
    except requests.exceptions.Timeout:
        print("❌ Web server timeout")
        return False
    except Exception as e:
        print(f"❌ Web server test failed: {str(e)}")
        return False

def main():
    """Run all tests"""
    print("🧪 Eero Dashboard Installation Test")
    print("=" * 40)
    
    tests = [
        ("Python Version", test_python_version),
        ("Dependencies", test_dependencies), 
        ("Configuration", test_configuration),
        ("Systemd Service", test_service),
        ("Web Server", test_web_server)
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test failed with error: {str(e)}")
            results.append((test_name, False))
    
    print("\n" + "=" * 40)
    print("📊 Test Results Summary:")
    print("=" * 40)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
        if result:
            passed += 1
    
    print(f"\nTests passed: {passed}/{len(results)}")
    
    if passed == len(results):
        print("\n🎉 All tests passed! Dashboard should be working correctly.")
        print("   Access your dashboard at: http://localhost:5000")
    else:
        print(f"\n⚠️  {len(results) - passed} test(s) failed. Check the output above for details.")
        print("   You may need to run setup.sh or check the installation.")
    
    return passed == len(results)

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)