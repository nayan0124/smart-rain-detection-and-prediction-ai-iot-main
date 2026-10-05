#!/usr/bin/env python3
"""
Test ESP32 connection on COM9
Reads serial data for 10 seconds
"""
import serial
import time

def test_esp32():
    try:
        print("🔍 Attempting to connect to COM9 at 115200 baud...")
        ser = serial.Serial('COM9', 115200, timeout=1)
        
        print("✓ Connected to COM9")
        print("=" * 60)
        print("Reading data from ESP32 (10 seconds)...\n")
        
        start_time = time.time()
        data_count = 0
        
        while time.time() - start_time < 10:
            if ser.in_waiting > 0:
                try:
                    line = ser.readline().decode('utf-8', errors='ignore').strip()
                    if line:
                        print(f"[{time.strftime('%H:%M:%S')}] {line}")
                        data_count += 1
                except Exception as e:
                    print(f"Error decoding: {e}")
        
        ser.close()
        print("\n" + "=" * 60)
        
        if data_count > 0:
            print(f"✓ SUCCESS: Received {data_count} messages from ESP32")
            print("✓ ESP32 is responding and transmitting data!")
        else:
            print("✗ No data received from ESP32")
            print("⚠ Check if:")
            print("  1. ESP32 is powered on")
            print("  2. Code is uploaded to ESP32")
            print("  3. Serial cable is properly connected")
            
    except serial.SerialException as e:
        print(f"✗ Failed to connect to COM9: {e}")
        print("\nTroubleshooting:")
        print("  • Is the ESP32 connected via USB?")
        print("  • Is the COM9 port correct?")
        print("  • Try: Get-PnpDevice -Class Ports (in PowerShell)")

if __name__ == "__main__":
    test_esp32()
