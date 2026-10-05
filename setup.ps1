# Smart Rain Detection System - Setup Script (Windows PowerShell)
# This script sets up the entire project for local development

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Rain Detection System - Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Prerequisites
Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Blue
$missingTools = @()

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    $missingTools += "Node.js"
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    $missingTools += "Python"
}

if ($missingTools.Count -gt 0) {
    Write-Host "Missing tools:" -ForegroundColor Red
    $missingTools | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
    Write-Host "Please install them before proceeding." -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ All prerequisites found" -ForegroundColor Green
Write-Host ""

# 2. Backend Setup
Write-Host "[2/6] Setting up Backend..." -ForegroundColor Blue
Push-Location backend
npm install
Write-Host "✓ Backend dependencies installed" -ForegroundColor Green
Pop-Location
Write-Host ""

# 3. Frontend Setup
Write-Host "[3/6] Setting up Frontend..." -ForegroundColor Blue
Push-Location frontend
npm install
Write-Host "✓ Frontend dependencies installed" -ForegroundColor Green
Pop-Location
Write-Host ""

# 4. AI/ML Setup
Write-Host "[4/6] Setting up AI/ML environment..." -ForegroundColor Blue
Push-Location ai

# Create venv if it doesn't exist
if (-not (Test-Path venv)) {
    Write-Host "Creating Python virtual environment..."
    python -m venv venv
}

# Activate venv
& .\venv\Scripts\Activate.ps1

pip install -r requirements.txt
Write-Host "✓ AI/ML dependencies installed" -ForegroundColor Green
Pop-Location
Write-Host ""

# 5. Environment Files
Write-Host "[5/6] Creating environment files..." -ForegroundColor Blue

if (-not (Test-Path "backend\.env")) {
    Copy-Item "backend\.env.example" "backend\.env"
    Write-Host "! Created backend\.env (Update with your credentials)" -ForegroundColor Yellow
}

if (-not (Test-Path "frontend\.env")) {
    Copy-Item "frontend\.env.example" "frontend\.env"
    Write-Host "! Created frontend\.env" -ForegroundColor Yellow
}
Write-Host ""

# 6. Database Setup (Optional)
Write-Host "[6/6] Database setup (requires PostgreSQL)..." -ForegroundColor Blue
Write-Host "! To set up database, run:" -ForegroundColor Yellow
Write-Host "  createdb smart_rain" -ForegroundColor Yellow
Write-Host "  psql -U postgres -d smart_rain -f database/schema.sql" -ForegroundColor Yellow
Write-Host ""

# 7. Train AI Models
Write-Host "[7/7] Training AI models..." -ForegroundColor Blue
Push-Location ai
& python train.py
Write-Host "✓ AI models trained!" -ForegroundColor Green
Pop-Location
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup Complete! ✓" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Blue
Write-Host "1. Start PostgreSQL database"
Write-Host "2. Run backend:  cd backend ; npm run dev"
Write-Host "3. Run frontend: cd frontend ; npm start"
Write-Host "4. Open http://localhost:3000 in your browser"
Write-Host ""
