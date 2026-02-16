#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stop Qwen3-TTS Studio UI and API Server
.DESCRIPTION
    Gracefully stops both the UI and API server processes
#>

Write-Host "=== Stopping Qwen3-TTS Studio ===" -ForegroundColor Cyan
Write-Host ""

# Change to script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$stopped = $false

# Try to use saved PIDs first
if (Test-Path ".running_pids.json") {
    try {
        $pids = Get-Content ".running_pids.json" | ConvertFrom-Json
        
        if ($pids.ApiPid) {
            $proc = Get-Process -Id $pids.ApiPid -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "Stopping API Server (PID: $($pids.ApiPid))..." -ForegroundColor Yellow
                Stop-Process -Id $pids.ApiPid -Force
                $stopped = $true
            }
        }
        
        if ($pids.UiPid) {
            $proc = Get-Process -Id $pids.UiPid -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "Stopping UI Server (PID: $($pids.UiPid))..." -ForegroundColor Yellow
                Stop-Process -Id $pids.UiPid -Force
                $stopped = $true
            }
        }
        
        Remove-Item ".running_pids.json" -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Could not use saved process IDs" -ForegroundColor Gray
    }
}

# Fallback: search for processes by script name
$apiProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*api_server.py*"
}

$uiProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*qwen_tts_ui.py*"
}

if ($apiProcesses) {
    Write-Host "Stopping API Server processes..." -ForegroundColor Yellow
    $apiProcesses | ForEach-Object {
        Write-Host "  Stopping PID: $($_.Id)" -ForegroundColor Gray
        Stop-Process -Id $_.Id -Force
        $stopped = $true
    }
}

if ($uiProcesses) {
    Write-Host "Stopping UI Server processes..." -ForegroundColor Yellow
    $uiProcesses | ForEach-Object {
        Write-Host "  Stopping PID: $($_.Id)" -ForegroundColor Gray
        Stop-Process -Id $_.Id -Force
        $stopped = $true
    }
}

Write-Host ""
if ($stopped) {
    Write-Host "Services stopped successfully" -ForegroundColor Green
} else {
    Write-Host "No running services found" -ForegroundColor Yellow
}
Write-Host ""
