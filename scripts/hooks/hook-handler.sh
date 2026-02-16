#!/bin/bash
# Unified hook handler for all GitHub Copilot hooks
# Uses hookEventName to determine which hook was fired

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/copilot-hooks.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Read input from stdin (hook data from Copilot)
INPUT=$(cat)

# Get timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Try to parse the JSON to get hook event name
HOOK_EVENT_NAME=$(echo "$INPUT" | jq -r '.hookEventName // "UNKNOWN"' 2>/dev/null || echo "UNKNOWN")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
ERROR_MSG=$(echo "$INPUT" | jq -r '.error // "unknown error"' 2>/dev/null || echo "unknown error")
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")

# Truncate prompt if too long
if [ -n "$PROMPT" ] && [ ${#PROMPT} -gt 80 ]; then
    PROMPT="${PROMPT:0:80}..."
fi

# Build log message based on hook event name
case "$HOOK_EVENT_NAME" in
    "SessionStart")
        MESSAGE="[$TIMESTAMP] SESSION_START - Copilot agent session started"
        ;;
    "SessionEnd")
        MESSAGE="[$TIMESTAMP] SESSION_END - Copilot agent session ended"
        ;;
    "UserPromptSubmit")
        if [ -n "$PROMPT" ]; then
            MESSAGE="[$TIMESTAMP] USER_PROMPT_SUBMITTED - Prompt: $PROMPT"
        else
            MESSAGE="[$TIMESTAMP] USER_PROMPT_SUBMITTED"
        fi
        ;;
    "PreToolUse")
        MESSAGE="[$TIMESTAMP] PRE_TOOL_USE - About to use tool: $TOOL_NAME"
        ;;
    "PostToolUse")
        MESSAGE="[$TIMESTAMP] POST_TOOL_USE - Finished using tool: $TOOL_NAME"
        ;;
    "ErrorOccurred")
        MESSAGE="[$TIMESTAMP] ERROR_OCCURRED - Error: $ERROR_MSG"
        ;;
    *)
        MESSAGE="[$TIMESTAMP] UNKNOWN_HOOK ($HOOK_EVENT_NAME)"
        ;;
esac

# Log the event
echo "$MESSAGE" >> "$LOG_FILE"

# For SessionStart, log git information
if [ "$HOOK_EVENT_NAME" = "SessionStart" ]; then
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null)
    GIT_USER=$(git config --get user.name 2>/dev/null)
    GIT_EMAIL=$(git config --get user.email 2>/dev/null)
    
    if [ -n "$GIT_BRANCH" ]; then
        echo "  Git Branch: $GIT_BRANCH" >> "$LOG_FILE"
    fi
    if [ -n "$GIT_REMOTE" ]; then
        echo "  Git Remote: $GIT_REMOTE" >> "$LOG_FILE"
    fi
    if [ -n "$GIT_USER" ] || [ -n "$GIT_EMAIL" ]; then
        if [ -n "$GIT_USER" ] && [ -n "$GIT_EMAIL" ]; then
            echo "  Git User: $GIT_USER <$GIT_EMAIL>" >> "$LOG_FILE"
        elif [ -n "$GIT_USER" ]; then
            echo "  Git User: $GIT_USER" >> "$LOG_FILE"
        else
            echo "  Git User: $GIT_EMAIL" >> "$LOG_FILE"
        fi
    fi
fi

# Always log the full input data
echo "  Input data: $INPUT" >> "$LOG_FILE"

# Exit successfully
exit 0
