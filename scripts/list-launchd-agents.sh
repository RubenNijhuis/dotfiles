#!/usr/bin/env bash
#
# List all installed LaunchD agents

echo "Installed LaunchD Agents"
echo "========================"
echo ""

# Get all com.user agents
agents=$(launchctl list | grep com.user | awk '{print $3}' | sort)

if [ -z "$agents" ]; then
    echo "No agents installed"
    exit 0
fi

# For each agent, show details
while IFS= read -r agent; do
    agent_name=$(echo "$agent" | sed 's/com.user.//')
    plist_path="$HOME/Library/LaunchAgents/${agent}.plist"

    echo "Agent: ${agent_name}"
    echo "  Label: ${agent}"

    if [ -f "$plist_path" ]; then
        # Extract schedule info
        if grep -q "StartCalendarInterval" "$plist_path"; then
            hour=$(defaults read "$plist_path" StartCalendarInterval Hour 2>/dev/null || echo "?")
            minute=$(defaults read "$plist_path" StartCalendarInterval Minute 2>/dev/null || echo "?")
            echo "  Schedule: Daily at ${hour}:${minute}"
        elif grep -q "StartInterval" "$plist_path"; then
            interval=$(defaults read "$plist_path" StartInterval 2>/dev/null || echo "?")
            echo "  Schedule: Every ${interval} seconds"
        fi

        # Check if script exists (try various naming patterns)
        found_script=""

        # Extract script path from plist
        plist_script=$(grep -A 5 "scripts/" "$plist_path" | grep ".sh" | sed 's/.*scripts\///' | sed 's/<.*$//' | tr -d ' ')

        if [ -n "$plist_script" ] && [ -f "$HOME/dotfiles/scripts/$plist_script" ]; then
            found_script="$plist_script"
        fi

        if [ -n "$found_script" ]; then
            echo "  Script: ✓ $found_script"
        else
            echo "  Script: ⚠ Not found"
        fi

        # Check log file
        log_path="$HOME/.local/log/${agent_name}.log"
        if [ -f "$log_path" ]; then
            last_run=$(tail -1 "$log_path" 2>/dev/null | grep -oE '\[.*?\]' | head -1 | tr -d '[]' || echo "Unknown")
            echo "  Last run: ${last_run}"
        fi
    fi

    echo ""
done <<< "$agents"

echo "Commands:"
echo "  Uninstall: ~/dotfiles/scripts/uninstall-launchd-agent.sh <name>"
echo "  Force run: launchctl kickstart -k gui/\$(id -u)/com.user.<name>"
echo "  View logs: tail -f ~/.local/log/<name>.log"
