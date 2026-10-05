#!/bin/bash
# stop.sh
# Bash script to stop all Smart Rain AI & IoT System processes for Linux/macOS

echo "========================================"
echo "Stopping Smart Rain System Services..."
echo "========================================"
echo ""

# 1. Stop Docker Database
echo "[1/3] Stopping PostgreSQL container..."
docker compose down
echo "✓ Docker containers stopped and removed"
echo ""

# 2. Stop Node/React processes (Backend on port 4000 and Frontend on port 3000)
echo "[2/3] Stopping Node/React processes..."
if command -v lsof >/dev/null 2>&1; then
    PORT_3000_PID=$(lsof -t -i:3000)
    if [ -n "$PORT_3000_PID" ]; then
        kill -9 $PORT_3000_PID
        echo "✓ Stopped frontend on port 3000 (PID: $PORT_3000_PID)"
    fi
    PORT_4000_PID=$(lsof -t -i:4000)
    if [ -n "$PORT_4000_PID" ]; then
        kill -9 $PORT_4000_PID
        echo "✓ Stopped backend on port 4000 (PID: $PORT_4000_PID)"
    fi
else
    # Fallback to pkill for node processes
    pkill -f "node"
    echo "✓ Sent stop signal to node processes"
fi
echo ""

# 3. Stop Python serial bridge processes
echo "[3/3] Stopping Python Serial Bridge..."
pkill -f "serial_to_dashboard.py"
echo "✓ Stopped Python serial bridge processes"
echo ""

echo "========================================"
echo "All services stopped successfully!"
echo "========================================"
