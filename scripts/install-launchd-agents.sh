#!/usr/bin/env bash
#
# Install all LaunchD agents from templates

set -e

TEMPLATES_DIR="$HOME/dotfiles/templates/launchd"
INSTALLED_COUNT=0
FAILED_COUNT=0

echo "Installing all LaunchD agents..."
echo ""

# Find all plist files
while IFS= read -r plist_file; do
    AGENT_NAME=$(basename "$plist_file" .plist | sed 's/com.user.//')

    echo "Installing: ${AGENT_NAME}"

    if "$HOME/dotfiles/scripts/install-launchd-agent.sh" "$AGENT_NAME"; then
        ((INSTALLED_COUNT++))
    else
        ((FAILED_COUNT++))
    fi

    echo ""
done < <(find "$TEMPLATES_DIR" -name "com.user.*.plist")

echo "========================================="
echo "Installation complete!"
echo "  Installed: $INSTALLED_COUNT"
echo "  Failed: $FAILED_COUNT"
echo ""
echo "List all agents:"
echo "  launchctl list | grep com.user"
