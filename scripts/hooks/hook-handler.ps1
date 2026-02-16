#!/usr/bin/env pwsh
# Unified hook handler for all GitHub Copilot hooks
# Uses hookEventName to determine which hook was fired

$LogDir = "logs"
$LogFile = "$LogDir/copilot-hooks.log"

# Create logs directory if it doesn't exist
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# Read input from stdin (hook data from Copilot)
$InputData = $input | Out-String

# Get timestamp
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Try to parse the JSON to get hook event name
$HookEventName = "UNKNOWN"
$ToolName = "unknown"
$ErrorMsg = "unknown error"
$Prompt = ""

try {
    $JsonData = $InputData | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($JsonData.hookEventName) {
        $HookEventName = $JsonData.hookEventName
    }
    if ($JsonData.tool_name) {
        $ToolName = $JsonData.tool_name
    }
    if ($JsonData.error) {
        $ErrorMsg = $JsonData.error
    }
    if ($JsonData.prompt) {
        $PromptPreview = $JsonData.prompt
        if ($PromptPreview.Length -gt 80) {
            $PromptPreview = $PromptPreview.Substring(0, 80) + "..."
        }
        $Prompt = " - Prompt: $PromptPreview"
    }
} catch {
    # If parsing fails, continue with unknown
}

# Build log message based on hook event name
$Message = switch ($HookEventName) {
    "SessionStart" { "[$Timestamp] SESSION_START - Copilot agent session started" }
    "SessionEnd" { "[$Timestamp] SESSION_END - Copilot agent session ended" }
    "UserPromptSubmit" { "[$Timestamp] USER_PROMPT_SUBMITTED$Prompt" }
    "PreToolUse" { "[$Timestamp] PRE_TOOL_USE - About to use tool: $ToolName" }
    "PostToolUse" { "[$Timestamp] POST_TOOL_USE - Finished using tool: $ToolName" }
    "ErrorOccurred" { "[$Timestamp] ERROR_OCCURRED - Error: $ErrorMsg" }
    default { "[$Timestamp] UNKNOWN_HOOK ($HookEventName)" }
}

# Log the event
Add-Content -Path $LogFile -Value $Message

# For SessionStart, log git information
if ($HookEventName -eq "SessionStart") {
    try {
        $GitBranch = git rev-parse --abbrev-ref HEAD 2>$null
        $GitRemote = git config --get remote.origin.url 2>$null
        $GitUser = git config --get user.name 2>$null
        $GitEmail = git config --get user.email 2>$null
        
        if ($GitBranch) {
            Add-Content -Path $LogFile -Value "  Git Branch: $GitBranch"
        }
        if ($GitRemote) {
            Add-Content -Path $LogFile -Value "  Git Remote: $GitRemote"
        }
        if ($GitUser -or $GitEmail) {
            $UserInfo = if ($GitUser -and $GitEmail) { "$GitUser <$GitEmail>" } elseif ($GitUser) { $GitUser } else { $GitEmail }
            Add-Content -Path $LogFile -Value "  Git User: $UserInfo"
        }
    } catch {
        # Silently ignore if git is not available or not a git repository
    }
}

# Always log the full input data
Add-Content -Path $LogFile -Value "  Input data: $InputData"

# Exit successfully
exit 0
