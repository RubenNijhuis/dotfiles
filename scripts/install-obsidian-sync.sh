#!/usr/bin/env bash
#
# Install Obsidian sync launchd agent

set -e

PLIST_SOURCE="$HOME/dotfiles/templates/launchd/com.user.obsidian-sync.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.user.obsidian-sync.plist"

echo "Installing Obsidian sync launchd agent..."

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

# Copy plist to LaunchAgents
cp "$PLIST_SOURCE" "$PLIST_DEST"

# Unload if already loaded (ignore errors)
launchctl unload "$PLIST_DEST" 2>/dev/null || true

# Load the agent
launchctl load "$PLIST_DEST"

echo "✓ Obsidian sync agent installed successfully"
echo "  Scheduled to run daily at 20:00 (8 PM)"
echo ""
echo "Useful commands:"
echo "  Check status: launchctl list | grep obsidian-sync"
echo "  View logs: tail -f ~/.local/log/obsidian-sync.log"
echo "  Manual run: ~/dotfiles/scripts/sync-obsidian.sh"
echo "  Uninstall: launchctl unload ~/Library/LaunchAgents/com.user.obsidian-sync.plist"
