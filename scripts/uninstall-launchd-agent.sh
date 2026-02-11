#!/usr/bin/env bash
#
# Uninstall a LaunchD agent

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <agent-name>"
    echo ""
    echo "Example: $0 obsidian-sync"
    echo ""
    echo "Installed agents:"
    launchctl list | grep com.user | awk '{print $3}' | sed 's/com.user./  - /' || echo "  None"
    exit 1
fi

AGENT_NAME="$1"
PLIST_NAME="com.user.${AGENT_NAME}"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

if [ ! -f "$PLIST_PATH" ]; then
    echo "Error: Agent '${AGENT_NAME}' is not installed"
    echo "Looking for: $PLIST_PATH"
    exit 1
fi

echo "Uninstalling LaunchD agent: ${AGENT_NAME}"

# Unload the agent
if launchctl unload "$PLIST_PATH" 2>/dev/null; then
    echo "  ✓ Agent unloaded"
else
    echo "  ⚠ Agent was not loaded"
fi

# Remove the plist file
rm "$PLIST_PATH"
echo "  ✓ Removed plist file"

echo ""
echo "✓ Agent '${AGENT_NAME}' uninstalled successfully"
