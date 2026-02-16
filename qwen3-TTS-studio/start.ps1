#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start Qwen3-TTS Studio UI and API Server
.DESCRIPTION
    Activates Python virtual environment, installs dependencies, and launches both services
#>

Write-Host "=== Qwen3-TTS Studio Launcher ===" -ForegroundColor Cyan
Write-Host ""

# Change to script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Check if venv exists
if (-not (Test-Path "venv\Scripts\Activate.ps1")) {
    Write-Host "Virtual environment not found. Creating..." -ForegroundColor Yellow
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create virtual environment" -ForegroundColor Red
        exit 1
    }
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Green
& "venv\Scripts\Activate.ps1"

# Install/update dependencies
Write-Host "Checking dependencies..." -ForegroundColor Green

if (Test-Path "requirements.txt") {
    Write-Host "Installing UI dependencies..." -ForegroundColor Yellow
    pip install -q -r requirements.txt
}

if (Test-Path "api_requirements.txt") {
    Write-Host "Installing API dependencies..." -ForegroundColor Yellow
    pip install -q -r api_requirements.txt
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Green
Write-Host ""

# Start API Server in background
Write-Host "Starting API Server (port 8001)..." -ForegroundColor Cyan
$ApiProcess = Start-Process -FilePath "python" -ArgumentList "api_server.py" -PassThru -WindowStyle Normal
Write-Host "  API Server started (PID: $($ApiProcess.Id))" -ForegroundColor Green

# Wait a moment for API to initialize
Start-Sleep -Seconds 2

# Start UI in background
Write-Host "Starting UI Server..." -ForegroundColor Cyan
$UiProcess = Start-Process -FilePath "python" -ArgumentList "qwen_tts_ui.py" -PassThru -WindowStyle Normal
Write-Host "  UI Server started (PID: $($UiProcess.Id))" -ForegroundColor Green

Write-Host ""
Write-Host "=== Services Running ===" -ForegroundColor Green
Write-Host "API Server: http://localhost:8001" -ForegroundColor White
Write-Host "UI will open in your browser automatically" -ForegroundColor White
Write-Host ""
Write-Host "To stop services, run: .\stop.ps1" -ForegroundColor Yellow
Write-Host "Or close the terminal windows that opened" -ForegroundColor Yellow
Write-Host ""

# Save process IDs for stop script
@{
    ApiPid = $ApiProcess.Id
    UiPid = $UiProcess.Id
    Timestamp = Get-Date
} | ConvertTo-Json | Out-File ".running_pids.json" -Encoding UTF8

Write-Host "Press Ctrl+C to exit this launcher (services will continue running)" -ForegroundColor Gray
Write-Host ""

# Keep script alive to show status
try {
    while ($true) {
        Start-Sleep -Seconds 5
        
        # Check if processes are still running
        $apiAlive = Get-Process -Id $ApiProcess.Id -ErrorAction SilentlyContinue
        $uiAlive = Get-Process -Id $UiProcess.Id -ErrorAction SilentlyContinue
        
        if (-not $apiAlive -and -not $uiAlive) {
            Write-Host "Both services have stopped" -ForegroundColor Red
            break
        }
    }
}
catch {
    Write-Host "Launcher stopped. Services continue running in background." -ForegroundColor Yellow
}
