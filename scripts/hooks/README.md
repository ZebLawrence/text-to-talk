# GitHub Copilot Hooks Test Scripts

This directory contains a unified hook handler for GitHub Copilot agent hooks. The handler uses the `hookEventName` field to determine which hook was triggered and logs all events to `logs/copilot-hooks.log`.

## Unified Hook Handler

Instead of separate scripts for each hook, a single script handles all hook types:
- **hook-handler.ps1** - PowerShell version
- **hook-handler.sh** - Bash version

The handler inspects the `hookEventName` field in the JSON input to determine which hook triggered it.

## Available Hook Events

- **SessionStart** - Copilot agent session starts
- **SessionEnd** - Copilot agent session ends
- **UserPromptSubmit** - User submits a prompt to Copilot
- **PreToolUse** - Before Copilot uses a tool
- **PostToolUse** - After Copilot uses a tool
- **ErrorOccurred** - When an error occurs during execution

## Configuration

The hooks are configured in [.github/hooks/hooks.json](../../.github/hooks/hooks.json). All hooks point to the same unified handler script.

## Testing Locally

You can test the hooks manually:

### PowerShell
```powershell
# Test with sample data
'{"hookEventName":"UserPromptSubmit","prompt":"Test prompt"}' | .\scripts\hooks\hook-handler.ps1

# Run full test suite
.\scripts\hooks\test-hooks.ps1

# View the log
Get-Content logs\copilot-hooks.log
```

### Bash
```bash
# Test with sample data
echo '{"hookEventName":"UserPromptSubmit","prompt":"Test prompt"}' | ./scripts/hooks/hook-handler.sh

# Run full test suite
./scripts/hooks/test-hooks.sh

# View the log
cat logs/copilot-hooks.log
```

## Hook Input Data

Each hook receives JSON data via stdin with fields like:
- `timestamp` - ISO 8601 timestamp
- `hookEventName` - Which hook was triggered
- `sessionId` - Unique session identifier
- `cwd` - Current working directory
- `tool_name` - Tool name (for PreToolUse/PostToolUse)
- `tool_input` - Tool input parameters
- `prompt` - User's prompt text (for UserPromptSubmit)
- `error` - Error message (for ErrorOccurred)

All input data is logged to help debug and understand the hook behavior.

## Requirements

- **PowerShell scripts**: PowerShell 5.1+ or PowerShell Core 7+
- **Bash scripts**: Bash shell (for Linux/macOS or WSL on Windows)
- **Optional**: `jq` for JSON parsing in bash scripts

## Making Scripts Executable (Linux/macOS)

```bash
chmod +x scripts/hooks/*.sh
```

## How They Work

When a Copilot agent session runs:
1. Copilot triggers hooks at specific points
2. JSON data is passed to the script via stdin
3. Scripts log the event with timestamp
4. All logs append to `logs/copilot-hooks.log`

Check the log file to verify hooks are being triggered!
