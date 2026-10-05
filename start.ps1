# start.ps1
# PowerShell script to start the Smart Rain AI & IoT System

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Smart Rain System Services..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Start Docker Database
Write-Host "[1/4] Starting PostgreSQL in Docker..." -ForegroundColor Blue
docker compose up postgres -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start PostgreSQL container. Please ensure Docker Desktop is running." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] PostgreSQL container started" -ForegroundColor Green
Write-Host ""

# 2. Start Backend API in a new PowerShell window
Write-Host "[2/4] Starting Backend API..." -ForegroundColor Blue
Start-Process powershell -WorkingDirectory "$pwd\backend" -ArgumentList "-NoExit", "-Command", '$Host.UI.RawUI.WindowTitle = "Smart Rain - Backend"; npm.cmd run dev'
Write-Host "[OK] Backend API launched in background window" -ForegroundColor Green
Write-Host ""

# 3. Start Frontend Dashboard in a new PowerShell window
Write-Host "[3/4] Starting Frontend Dashboard..." -ForegroundColor Blue
Start-Process powershell -WorkingDirectory "$pwd\frontend" -ArgumentList "-NoExit", "-Command", '$Host.UI.RawUI.WindowTitle = "Smart Rain - Frontend"; npm.cmd start'
Write-Host "[OK] Frontend Dashboard launched in background window" -ForegroundColor Green
Write-Host ""

# 4. Start Python Serial Bridge in a new PowerShell window
Write-Host "[4/4] Starting Python Serial Bridge..." -ForegroundColor Blue
$pythonPath = "python"
if (Test-Path "ai\venv\Scripts\python.exe") {
    $pythonPath = "ai\venv\Scripts\python.exe"
    Write-Host "Using Python virtual environment at ai\venv" -ForegroundColor Gray
} elseif (Test-Path "venv\Scripts\python.exe") {
    $pythonPath = "venv\Scripts\python.exe"
    Write-Host "Using Python virtual environment at venv" -ForegroundColor Gray
} elseif (Test-Path ".venv\Scripts\python.exe") {
    $pythonPath = ".venv\Scripts\python.exe"
    Write-Host "Using Python virtual environment at .venv" -ForegroundColor Gray
} else {
    Write-Host "Using system Python executable" -ForegroundColor Gray
}

Start-Process powershell -WorkingDirectory "$pwd" -ArgumentList "-NoExit", "-Command", ('$Host.UI.RawUI.WindowTitle = "Smart Rain - Serial Bridge"; ' + $pythonPath + ' serial_to_dashboard.py')
Write-Host "[OK] Python Serial Bridge launched in background window" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "All services launched successfully!" -ForegroundColor Green
Write-Host "Opening dashboard at http://localhost:3000 in 3 seconds..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Start-Sleep -Seconds 3
Start-Process "http://localhost:3000"
