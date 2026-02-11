#!/usr/bin/env bash
#
# DEPRECATED: Use install-launchd-agent.sh instead
# This script is kept for backward compatibility

echo "⚠️  This script is deprecated."
echo "   Use: ~/dotfiles/scripts/install-launchd-agent.sh obsidian-sync"
echo ""
echo "Redirecting to new installer..."
echo ""

exec "$HOME/dotfiles/scripts/install-launchd-agent.sh" obsidian-sync
