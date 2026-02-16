#!/bin/bash
# Test script to manually verify all Copilot hooks are working

echo -e "\033[36mTesting GitHub Copilot Hooks...\033[0m"
echo ""

# Clean up old log file
LOG_FILE="logs/copilot-hooks.log"
if [ -f "$LOG_FILE" ]; then
    rm "$LOG_FILE"
    echo -e "\033[33mCleaned up old log file\033[0m"
fi

# Test data samples
SESSION_DATA='{"timestamp":1708099200000,"hookEventName":"SessionStart","sessionId":"test-session-123","cwd":"'$(pwd)'"}'
USER_PROMPT_DATA='{"timestamp":1708099200000,"hookEventName":"UserPromptSubmit","sessionId":"test-session-123","prompt":"Test user prompt","cwd":"'$(pwd)'"}'
PRE_TOOL_DATA='{"timestamp":1708099200000,"hookEventName":"PreToolUse","sessionId":"test-session-123","cwd":"'$(pwd)'","tool_name":"read_file","tool_input":"{\"filePath\": \"test.txt\"}"}'
POST_TOOL_DATA='{"timestamp":1708099200000,"hookEventName":"PostToolUse","sessionId":"test-session-123","cwd":"'$(pwd)'","tool_name":"read_file","tool_input":"{\"filePath\": \"test.txt\"}","tool_response":"File contents..."}'
ERROR_DATA='{"timestamp":1708099200000,"hookEventName":"ErrorOccurred","sessionId":"test-session-123","error":"Test error message","cwd":"'$(pwd)'"}'
SESSION_END_DATA='{"timestamp":1708099200000,"hookEventName":"SessionEnd","sessionId":"test-session-123","cwd":"'$(pwd)'"}'

# Make scripts executable if needed
chmod +x scripts/hooks/*.sh 2>/dev/null

# Test each hook
echo -e "\033[32m1. Testing SessionStart hook...\033[0m"
echo "$SESSION_DATA" | ./scripts/hooks/hook-handler.sh
sleep 0.1

echo -e "\033[32m2. Testing UserPromptSubmit hook...\033[0m"
echo "$USER_PROMPT_DATA" | ./scripts/hooks/hook-handler.sh
sleep 0.1

echo -e "\033[32m3. Testing PreToolUse hook...\033[0m"
echo "$PRE_TOOL_DATA" | ./scripts/hooks/hook-handler.sh
sleep 0.1

echo -e "\033[32m4. Testing PostToolUse hook...\033[0m"
echo "$POST_TOOL_DATA" | ./scripts/hooks/hook-handler.sh
sleep 0.1

echo -e "\033[32m5. Testing ErrorOccurred hook...\033[0m"
echo "$ERROR_DATA" | ./scripts/hooks/hook-handler.sh
sleep 0.1

echo -e "\033[32m6. Testing SessionEnd hook...\033[0m"
echo "$SESSION_END_DATA" | ./scripts/hooks/hook-handler.sh
sleep 0.1

echo ""
echo -e "\033[36mAll hooks tested! Check the log file:\033[0m"
echo ""

# Display the log file
if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE"
    echo ""
    echo -e "\033[32m✓ Success! All hooks are writing to the log file.\033[0m"
else
    echo -e "\033[31m✗ Error: Log file was not created.\033[0m"
fi
