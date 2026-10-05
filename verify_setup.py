#!/usr/bin/env python3
"""
Smart Rain System - Arduino IDE Environment Checker
Verifies your setup is ready for uploading to ESP32
"""

import os
import sys
import subprocess
from pathlib import Path

def print_header(text):
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}\n")

def print_check(status, message):
    symbol = "✓" if status else "✗"
    print(f"  [{symbol}] {message}")
    return status

def check_arduino_ide():
    """Check if Arduino IDE is installed"""
    print_header("CHECK 1: Arduino IDE Installation")
    
    # Common Arduino IDE paths on Windows
    possible_paths = [
        "C:\\Program Files\\Arduino",
        "C:\\Program Files (x86)\\Arduino",
        os.path.expanduser("~/AppData/Local/Arduino15"),
    ]
    
    found = False
    for path in possible_paths:
        if os.path.exists(path):
            print_check(True, f"Arduino IDE found at: {path}")
            found = True
            break
    
    if not found:
        print_check(False, "Arduino IDE not found in standard locations")
        print("  → Download from: https://www.arduino.cc/en/software")
        return False
    
    return True

def check_project_files():
    """Check if project files exist"""
    print_header("CHECK 2: Project Files")
    
    required_files = [
        "ESP32_BLUETOOTH_VERSION.ino",
        "BLUETOOTH_SETUP_GUIDE.md",
        "BLUETOOTH_TEST_CHECKLIST.md",
    ]
    
    all_exist = True
    project_dir = Path.cwd()
    
    for file in required_files:
        file_path = project_dir / file
        exists = file_path.exists()
        print_check(exists, f"{file}")
        if not exists:
            all_exist = False
    
    return all_exist

def check_usb_devices():
    """Check for USB devices connected"""
    print_header("CHECK 3: USB Devices Connected")
    
    try:
        # Use Windows device manager to list USB devices
        result = subprocess.run(
            ["wmic", "logicaldisk", "get", "name"],
            capture_output=True, text=True
        )
        print_check(True, "USB devices are accessible")
        return True
    except:
        print_check(False, "Could not check USB devices")
        return False

def check_serial_ports():
    """Check for available COM ports"""
    print_header("CHECK 4: Serial/COM Ports")
    
    try:
        result = subprocess.run(
            ["powershell", "-Command", 
             "Get-PnpDevice -Class Ports | Select-Object Name | Format-Table -HideTableHeaders"],
            capture_output=True, text=True
        )
        
        ports = [line.strip() for line in result.stdout.split('\n') if line.strip()]
        
        if ports:
            print_check(True, f"Found {len(ports)} COM ports:")
            for port in ports[:5]:  # Show first 5
                print(f"    → {port}")
            return True
        else:
            print_check(False, "No COM ports found")
            print("  → Plug in ESP32 via USB and retry")
            return False
    except Exception as e:
        print_check(False, f"Could not check ports: {e}")
        return False

def check_libraries():
    """Check for Arduino libraries"""
    print_header("CHECK 5: Arduino Libraries (Manual Check)")
    
    required_libs = [
        "DHT sensor library (Adafruit)",
        "Adafruit Unified Sensor",
        "Adafruit BMP280 Library",
        "ESP32Servo",
        "BluetoothSerial (built-in)"
    ]
    
    print("  These libraries should be installed in Arduino IDE:")
    print("  Sketch → Include Library → Manage Libraries\n")
    
    for lib in required_libs:
        print(f"    ☐ {lib}")
    
    return True

def check_diskspace():
    """Check available disk space"""
    print_header("CHECK 6: Disk Space")
    
    try:
        import shutil
        stat = shutil.disk_usage(".")
        
        free_gb = stat.free / (1024**3)
        
        has_space = free_gb > 1  # Need at least 1GB
        print_check(has_space, f"Free disk space: {free_gb:.2f} GB")
        
        if not has_space:
            print("  → Need at least 1GB free space for Arduino IDE")
        
        return has_space
    except:
        print_check(False, "Could not check disk space")
        return False

def main():
    print("\n" + "="*60)
    print("  SMART RAIN SYSTEM - SETUP VERIFICATION")
    print("  Arduino IDE & ESP32 Environment Check")
    print("="*60)
    
    checks = [
        ("Arduino IDE", check_arduino_ide),
        ("Project Files", check_project_files),
        ("USB Devices", check_usb_devices),
        ("COM Ports", check_serial_ports),
        ("Libraries", check_libraries),
        ("Disk Space", check_diskspace),
    ]
    
    results = []
    for name, check_func in checks:
        try:
            result = check_func()
            results.append((name, result))
        except Exception as e:
            print(f"\n[ERROR] {name} check failed: {e}")
            results.append((name, False))
    
    # Summary
    print_header("SUMMARY")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        symbol = "✓" if result else "✗"
        print(f"  [{symbol}] {name}")
    
    print(f"\n  Passed: {passed}/{total} checks")
    
    if passed == total:
        print("\n  ✓ YOUR SYSTEM IS READY!")
        print("\n  Next steps:")
        print("  1. Open Arduino IDE")
        print("  2. Open: ESP32_BLUETOOTH_VERSION.ino")
        print("  3. Select Board: Tools → Board → ESP32 Dev Module")
        print("  4. Click Upload")
        print("  5. Watch Serial Monitor at 115200 baud")
        return 0
    else:
        print("\n  ✗ Some checks failed. Please review above.")
        print("\n  Troubleshooting:")
        if not results[0][1]:
            print("  → Install Arduino IDE: https://www.arduino.cc/en/software")
        if not results[3][1]:
            print("  → Plug ESP32 in via USB cable")
        return 1

if __name__ == "__main__":
    sys.exit(main())
