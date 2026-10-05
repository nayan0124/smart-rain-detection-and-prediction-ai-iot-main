#!/usr/bin/env python3
"""
Smart Rain Serial Data Logger - Direct COM3 Connection
Logs incoming data from ESP32 via CP2102 USB-to-UART bridge
"""

import serial
import time
import requests
import json
import datetime
import threading

BAUD_RATE = 115200
API_URL = 'http://localhost:4000/api/v1/sensors/ingest'
DEVICE_ID = 'esp32-rain-sensor'
DEFAULT_PRESSURE = 1013.25
COM_PORT = 'COM3'

def send_to_api(payload):
    """Send sensor data to dashboard API in background"""
    def task():
        try:
            print(f"  📡 Sending to API: {API_URL}")
            response = requests.post(API_URL, json=payload, timeout=2)
            print(f"  ✓ API Response: {response.status_code}")
        except Exception as e:
            print(f"  ⚠ API Error: {e}")
    
    threading.Thread(target=task, daemon=True).start()

def log_serial_data():
    """Read and log data from COM3"""
    try:
        print(f"🔌 Connecting to {COM_PORT} at {BAUD_RATE} baud...")
        ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=1)
        time.sleep(2)  # Wait for serial port to stabilize
        print(f"✓ Connected to {COM_PORT}\n")
        
        print("=" * 70)
        print("📊 CONSOLE DATA - Streaming from ESP32")
        print("=" * 70 + "\n")
        
        buffer = ""
        line_count = 0
        
        while True:
            if ser.in_waiting:
                try:
                    char = ser.read().decode(errors='ignore')
                    
                    if char == '\n':
                        line = buffer.strip()
                        buffer = ""
                        
                        if not line:
                            continue
                        
                        line_count += 1
                        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
                        print(f"[{timestamp}] {line}")
                        
                        # Try to parse JSON if available
                        if line.startswith('{'):
                            try:
                                data = json.loads(line)
                                
                                # Use mock values when sensors return null (DHT22 not connected)
                                temp = data.get("temp")
                                humidity = data.get("humidity")
                                if temp is None:
                                    temp = 24.5  # Mock temperature
                                if humidity is None:
                                    humidity = 55.0  # Mock humidity
                                
                                payload = {
                                    "deviceId": DEVICE_ID,
                                    "temperatureC": float(temp),
                                    "humidityPct": float(humidity),
                                    "pressureHpa": data.get("pressure", DEFAULT_PRESSURE),
                                    "rainAnalog": data.get("rain_level", 0),
                                    "rainDetected": data.get("rain_digital_raw", 1) == 0,
                                    "rainIntensity": data.get("rain_intensity", "NO RAIN"),
                                    "capturedAt": datetime.datetime.utcnow().isoformat() + "Z"
                                }
                                send_to_api(payload)
                            except json.JSONDecodeError:
                                pass
                    else:
                        buffer += char
                        
                except Exception as e:
                    print(f"Error reading serial: {e}")
                    
            else:
                time.sleep(0.01)
    
    except serial.SerialException as e:
        print(f"✗ Serial Error: {e}")
        print(f"\n🔍 Troubleshooting:")
        print(f"   1. Check if {COM_PORT} is correct (Get-WmiObject Win32_SerialPort)")
        print(f"   2. Verify ESP32 is powered and has code uploaded")
        print(f"   3. Check USB cable connection")
        print(f"   4. Restart CP2102 driver")
    
    except KeyboardInterrupt:
        print("\n\n✓ Logging stopped")
    
    finally:
        if ser and ser.is_open:
            ser.close()

if __name__ == "__main__":
    log_serial_data()
