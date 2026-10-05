#!/bin/bash
# start.sh
# Bash script to start the Smart Rain AI & IoT System for Linux/macOS

echo "========================================"
echo "Starting Smart Rain System Services..."
echo "========================================"
echo ""

# 1. Start Docker Database
echo "[1/4] Starting PostgreSQL in Docker..."
docker compose up postgres -d
if [ $? -ne 0 ]; then
    echo "Failed to start PostgreSQL container. Please ensure Docker is running."
    exit 1
fi
echo "✓ PostgreSQL container started"
echo ""

# 2. Start Backend API
echo "[2/4] Starting Backend API..."
cd backend && npm run dev &
BACKEND_PID=$!
cd ..
echo "✓ Backend API launched in background (PID: $BACKEND_PID)"
echo ""

# 3. Start Frontend Dashboard
echo "[3/4] Starting Frontend Dashboard..."
cd frontend && npm start &
FRONTEND_PID=$!
cd ..
echo "✓ Frontend Dashboard launched in background (PID: $FRONTEND_PID)"
echo ""

# 4. Start Python Serial Bridge
echo "[4/4] Starting Python Serial Bridge..."
PYTHON_PATH="python3"
if [ -f "ai/venv/bin/python" ]; then
    PYTHON_PATH="ai/venv/bin/python"
    echo "Using Python virtual environment at ai/venv"
elif [ -f "venv/bin/python" ]; then
    PYTHON_PATH="venv/bin/python"
    echo "Using Python virtual environment at venv"
elif [ -f ".venv/bin/python" ]; then
    PYTHON_PATH=".venv/bin/python"
    echo "Using Python virtual environment at .venv"
else
    echo "Using system python3 executable"
fi

$PYTHON_PATH serial_to_dashboard.py &
PYTHON_PID=$!
echo "✓ Python Serial Bridge launched in background (PID: $PYTHON_PID)"
echo ""

echo "========================================"
echo "All services launched successfully!"
echo "Opening dashboard at http://localhost:3000 in 3 seconds..."
echo "========================================"

sleep 3
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:3000" >/dev/null 2>&1
elif command -v open >/dev/null 2>&1; then
  open "http://localhost:3000" >/dev/null 2>&1
fi
