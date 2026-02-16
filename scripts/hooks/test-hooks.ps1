#!/usr/bin/env pwsh
# Test script to manually verify all Copilot hooks are working

Write-Host "Testing GitHub Copilot Hooks..." -ForegroundColor Cyan
Write-Host ""

# Clean up old log file
$LogFile = "logs\copilot-hooks.log"
if (Test-Path $LogFile) {
    Remove-Item $LogFile
    Write-Host "Cleaned up old log file" -ForegroundColor Yellow
}

# Test data samples
$sessionData = @{
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    hookEventName = "SessionStart"
    sessionId = "test-session-123"
    cwd = Get-Location
} | ConvertTo-Json -Compress

$userPromptData = @{
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    hookEventName = "UserPromptSubmit"
    sessionId = "test-session-123"
    prompt = "Test user prompt"
    cwd = Get-Location
} | ConvertTo-Json -Compress

$preToolData = @{
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    hookEventName = "PreToolUse"
    sessionId = "test-session-123"
    cwd = Get-Location
    tool_name = "read_file"
    tool_input = @{filePath = "test.txt"}
} | ConvertTo-Json -Compress

$postToolData = @{
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    hookEventName = "PostToolUse"
    sessionId = "test-session-123"
    cwd = Get-Location
    tool_name = "read_file"
    tool_input = @{filePath = "test.txt"}
    tool_response = "File contents..."
} | ConvertTo-Json -Compress

$errorData = @{
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    hookEventName = "ErrorOccurred"
    sessionId = "test-session-123"
    error = "Test error message"
    cwd = Get-Location
} | ConvertTo-Json -Compress

$sessionEndData = @{
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    hookEventName = "SessionEnd"
    sessionId = "test-session-123"
    cwd = Get-Location
} | ConvertTo-Json -Compress

# Test each hook
Write-Host "1. Testing SessionStart hook..." -ForegroundColor Green
$sessionData | .\scripts\hooks\hook-handler.ps1
Start-Sleep -Milliseconds 100

Write-Host "2. Testing UserPromptSubmit hook..." -ForegroundColor Green
$userPromptData | .\scripts\hooks\hook-handler.ps1
Start-Sleep -Milliseconds 100

Write-Host "3. Testing PreToolUse hook..." -ForegroundColor Green
$preToolData | .\scripts\hooks\hook-handler.ps1
Start-Sleep -Milliseconds 100

Write-Host "4. Testing PostToolUse hook..." -ForegroundColor Green
$postToolData | .\scripts\hooks\hook-handler.ps1
Start-Sleep -Milliseconds 100

Write-Host "5. Testing ErrorOccurred hook..." -ForegroundColor Green
$errorData | .\scripts\hooks\hook-handler.ps1
Start-Sleep -Milliseconds 100

Write-Host "6. Testing SessionEnd hook..." -ForegroundColor Green
$sessionEndData | .\scripts\hooks\hook-handler.ps1
Start-Sleep -Milliseconds 100

Write-Host ""
Write-Host "All hooks tested! Check the log file:" -ForegroundColor Cyan
Write-Host ""

# Display the log file
if (Test-Path $LogFile) {
    Get-Content $LogFile | ForEach-Object {
        Write-Host $_ -ForegroundColor White
    }
    Write-Host ""
    Write-Host "[SUCCESS] All hooks are writing to the log file." -ForegroundColor Green
} else {
    Write-Host "[ERROR] Log file was not created." -ForegroundColor Red
}
