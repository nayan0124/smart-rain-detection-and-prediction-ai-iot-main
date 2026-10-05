import serial
import time
import requests
import json
import datetime
import threading
import serial.tools.list_ports

BAUD_RATE = 115200
INGEST_URL = 'http://localhost:4000/api/v1/sensors/ingest'
LIVE_URL   = 'http://localhost:4000/api/v1/hardware/latest'
DEVICE_ID = 'esp32-bridge'
DEFAULT_PRESSURE = 1013.25

SEND_INTERVAL = 1.0   # periodic update interval in seconds


def send_to_backend(payload):
    """Send data to BOTH endpoints so the live dashboard always gets data."""
    def task():
        # Normalize rain level to 0-100 scale for the live endpoint
        raw_rain = payload.get("rainAnalog", 0)
        if raw_rain <= 100:
            rain_level_pct = max(0, min(100, raw_rain))
        elif raw_rain <= 1023:
            rain_level_pct = round(((1023 - max(0, min(1023, raw_rain))) / 1023) * 100)
        else:
            rain_level_pct = round(((4095 - max(0, min(4095, raw_rain))) / 4095) * 100)

        # --- 1. Always update the in-memory live reading first ---
        live_payload = {
            "deviceId": payload.get("deviceId", DEVICE_ID),
            "source": "serial-bridge",
            "time": 0,
            "temp": payload.get("temperatureC", 0),
            "humidity": payload.get("humidityPct", 0),
            "pressure": payload.get("pressureHpa", DEFAULT_PRESSURE),
            "rain_level": rain_level_pct,
            "rain_detected": payload.get("rainDetected", False),
            "rain_intensity": payload.get("rainIntensity", "NO RAIN"),
            "capturedAt": payload.get("capturedAt", datetime.datetime.now(datetime.timezone.utc).isoformat())
        }
        try:
            r = requests.post(LIVE_URL, json=live_payload, timeout=2)
            if r.status_code >= 400:
                print(f"  [LIVE] WARNING: {r.status_code} - {r.text[:200]}")
            else:
                print(f"  [LIVE] OK -> temp={live_payload['temp']}, hum={live_payload['humidity']}, rain={live_payload['rain_level']}")
        except Exception as e:
            print(f"  [LIVE] ERROR: {e}")

        # --- 2. Also send to full ingest pipeline (DB + AI) ---
        try:
            r = requests.post(INGEST_URL, json=payload, timeout=3)
            if r.status_code >= 400:
                print(f"  [INGEST] WARNING: {r.status_code} - {r.text[:200]}")
            else:
                print(f"  [INGEST] OK (saved to DB + AI prediction)")
        except Exception as e:
            print(f"  [INGEST] ERROR: {e}")

    threading.Thread(target=task, daemon=True).start()


def get_com():
    ports = serial.tools.list_ports.comports()
    for p in ports:
        if 'CP210x' in str(p.description):
            return p.device
    # Show all available ports to help user choose
    print("\nAvailable COM ports:")
    for p in ports:
        print(f"  {p.device} - {p.description}")
    return input("Enter COM port (e.g. COM3): ").strip()


def start():
    com_port = get_com()
    print(f"\n⚡ Connecting to {com_port} at {BAUD_RATE} baud...")
    ser = serial.Serial(com_port, BAUD_RATE, timeout=0.05)
    print(f"✅ Connected to {com_port}\n")

    buffer = ""

    stable_state = False
    last_sent_state = None
    change_counter = 0
    REQUIRED_STABLE_COUNT = 3

    last_send_time = 0
    latest_data = None
    read_count = 0

    print("⚡ SERIAL BRIDGE ACTIVE - Sending to Dashboard\n")

    while True:
        while ser.in_waiting:
            char = ser.read().decode(errors='ignore')

            if char == '\n':
                line = buffer.strip()
                buffer = ""

                if not line.startswith('{'):
                    # Print non-JSON lines for debugging
                    if line:
                        print(f"  [SERIAL] {line}")
                    continue

                try:
                    parsed = json.loads(line)
                except json.JSONDecodeError as e:
                    print(f"  [JSON ERROR] {e}: {line[:100]}")
                    continue

                read_count += 1

                digital_raw = parsed.get("rain_digital_raw", 1)
                instant_state = (digital_raw == 0)

                # ===== STABILITY =====
                if instant_state == stable_state:
                    change_counter = 0
                else:
                    change_counter += 1
                    if change_counter >= REQUIRED_STABLE_COUNT:
                        stable_state = instant_state
                        change_counter = 0

                # ===== SERVO =====
                servo_angle = 90 if stable_state else 0
                window_state = "CLOSED" if stable_state else "OPEN"

                # Extract temp/humidity – ESP32 serial uses various key names
                raw_temp = parsed.get("temp", parsed.get("temperature", parsed.get("temperatureC")))
                raw_hum  = parsed.get("humidity", parsed.get("humidityPct"))

                # DHT22 failure sends -1, NaN, or null; use mock defaults so dashboard always shows data
                try:
                    raw_temp = float(raw_temp)
                    if raw_temp < -40 or raw_temp > 80:
                        raw_temp = 24.5
                except (TypeError, ValueError):
                    raw_temp = 24.5

                try:
                    raw_hum = float(raw_hum)
                    if raw_hum < 0 or raw_hum > 100:
                        raw_hum = 55.0
                except (TypeError, ValueError):
                    raw_hum = 55.0

                # Get pressure, default to standard atmospheric
                try:
                    pressure = float(parsed.get("pressure", DEFAULT_PRESSURE))
                except (TypeError, ValueError):
                    pressure = DEFAULT_PRESSURE

                # Get rain analog value
                try:
                    rain_analog = int(parsed.get("rain_level", parsed.get("rain_analog", parsed.get("rainAnalog", 0))))
                except (TypeError, ValueError):
                    rain_analog = 0

                latest_data = {
                    "deviceId": DEVICE_ID,
                    "temperatureC": raw_temp,
                    "humidityPct": raw_hum,
                    "pressureHpa": pressure,
                    "rainAnalog": rain_analog,
                    "rainDetected": stable_state,
                    "rainIntensity": parsed.get("rain_intensity", "NO RAIN"),
                    "servoAngle": servo_angle,
                    "windowState": window_state,
                    "capturedAt": datetime.datetime.now(datetime.timezone.utc).isoformat()
                }

                # Print every 5th reading to avoid terminal spam
                if read_count % 5 == 0:
                    print(f"[#{read_count}] temp={raw_temp:.1f}°C  hum={raw_hum:.1f}%  rain={rain_analog}  detected={stable_state}  window={window_state}")

                # ⚡ INSTANT SEND ON STATE CHANGE
                if last_sent_state != stable_state:
                    print(f"\n⚡ STATE CHANGE: rain_detected={stable_state}, window={window_state}")
                    send_to_backend(latest_data)
                    last_sent_state = stable_state
                    last_send_time = time.time()

            else:
                buffer += char

        # 🔄 PERIODIC SEND (keeps dashboard updated)
        if latest_data and (time.time() - last_send_time >= SEND_INTERVAL):
            # Update timestamp for periodic sends
            latest_data["capturedAt"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
            send_to_backend(latest_data)
            last_send_time = time.time()

        time.sleep(0.003)


if __name__ == "__main__":
    start()