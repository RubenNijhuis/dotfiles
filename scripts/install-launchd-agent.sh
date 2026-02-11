#!/usr/bin/env bash
#
# Install a single LaunchD agent from templates

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <agent-name>"
    echo ""
    echo "Example: $0 obsidian-sync"
    echo ""
    echo "Available agents:"
    find "$HOME/dotfiles/templates/launchd" -name "com.user.*.plist" -exec basename {} .plist \; | sed 's/com.user./  - /'
    exit 1
fi

AGENT_NAME="$1"
PLIST_NAME="com.user.${AGENT_NAME}"
PLIST_SOURCE="$HOME/dotfiles/templates/launchd/${PLIST_NAME}.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

# Check if plist exists
if [ ! -f "$PLIST_SOURCE" ]; then
    echo "Error: Agent '${AGENT_NAME}' not found"
    echo "Looking for: $PLIST_SOURCE"
    echo ""
    echo "Available agents:"
    find "$HOME/dotfiles/templates/launchd" -name "com.user.*.plist" -exec basename {} .plist \; | sed 's/com.user./  - /'
    exit 1
fi

echo "Installing LaunchD agent: ${AGENT_NAME}"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

# Copy plist to LaunchAgents
cp "$PLIST_SOURCE" "$PLIST_DEST"
echo "  ✓ Copied plist to ~/Library/LaunchAgents/"

# Unload if already loaded (ignore errors)
launchctl unload "$PLIST_DEST" 2>/dev/null || true

# Load the agent
if launchctl load "$PLIST_DEST"; then
    echo "  ✓ Agent loaded successfully"
else
    echo "  ✗ Failed to load agent"
    exit 1
fi

# Validate plist
if plutil -lint "$PLIST_DEST" > /dev/null 2>&1; then
    echo "  ✓ Plist validation passed"
else
    echo "  ⚠ Warning: Plist validation failed"
fi

echo ""
echo "✓ Agent '${AGENT_NAME}' installed successfully"
echo ""
echo "Useful commands:"
echo "  Check status: launchctl list | grep ${AGENT_NAME}"
echo "  View info: launchctl print gui/\$(id -u)/${PLIST_NAME}"
echo "  Force run: launchctl kickstart -k gui/\$(id -u)/${PLIST_NAME}"
echo "  Uninstall: ~/dotfiles/scripts/uninstall-launchd-agent.sh ${AGENT_NAME}"
