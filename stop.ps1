# stop.ps1
# PowerShell script to stop all Smart Rain AI & IoT System processes

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Stopping Smart Rain System Services..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# 1. Stop Docker Database
Write-Host "[1/3] Stopping PostgreSQL container..." -ForegroundColor Blue
docker compose down
Write-Host "[OK] Docker containers stopped and removed" -ForegroundColor Green
Write-Host ""

# 2. Stop Node/React processes (Backend on port 4000 and Frontend on port 3000)
Write-Host "[2/3] Stopping Node/React processes..." -ForegroundColor Blue
$connections = Get-NetTCPConnection -LocalPort 3000, 4000 -ErrorAction SilentlyContinue
if ($connections) {
    # Keep track of stopped PIDs to avoid duplicate messages
    $stoppedPids = @{}
    $connections | ForEach-Object {
        $targetPid = $_.OwningProcess
        if (-not $stoppedPids.ContainsKey($targetPid)) {
            $stoppedPids[$targetPid] = $true
            Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "[OK] Stopped active Node/React processes on ports 3000 and 4000" -ForegroundColor Green
} else {
    Write-Host "No active processes found on ports 3000 or 4000" -ForegroundColor Yellow
}
Write-Host ""

# 3. Stop Python serial bridge processes
Write-Host "[3/3] Stopping Python Serial Bridge..." -ForegroundColor Blue
$bridgeProcesses = Get-CimInstance Win32_Process -Filter "Name = 'python.exe' AND CommandLine LIKE '%serial_to_dashboard.py%'" -ErrorAction SilentlyContinue
if ($bridgeProcesses) {
    $bridgeProcesses | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Stopped Python serial bridge processes" -ForegroundColor Green
} else {
    Write-Host "No active Python serial bridge processes found" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "All services stopped successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
