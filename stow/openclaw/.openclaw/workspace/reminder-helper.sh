#!/bin/bash
# OpenClaw Reminder Helper
# Usage: ./reminder-helper.sh "TIME" "MESSAGE"
# Example: ./reminder-helper.sh "16:00" "Check DJ cables in Leiden"
# Example: ./reminder-helper.sh "+30m" "Take a break"

set -e

PHONE="+31628634244"
CHANNEL="whatsapp"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <time> <message>"
    echo ""
    echo "Time formats:"
    echo "  - HH:MM (e.g., '16:00' for 4pm today)"
    echo "  - +duration (e.g., '+30m', '+2h', '+1d')"
    echo "  - ISO timestamp (e.g., '2026-02-12T16:00:00')"
    echo ""
    echo "Examples:"
    echo "  $0 '16:00' 'Check DJ cables in Leiden'"
    echo "  $0 '+30m' 'Take a break'"
    echo "  $0 '2026-02-13T09:00:00' 'Morning reminder'"
    exit 1
fi

TIME="$1"
MESSAGE="$2"

# Convert HH:MM to ISO timestamp for today
if [[ "$TIME" =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
    TODAY=$(date +%Y-%m-%d)
    TIME="${TODAY}T${TIME}:00"
fi

# Convert +duration to duration (remove +)
if [[ "$TIME" =~ ^\+(.+)$ ]]; then
    TIME="${BASH_REMATCH[1]}"
fi

# Generate a simple name from the message (first 30 chars)
NAME=$(echo "$MESSAGE" | cut -c1-30)

echo "Creating reminder..."
echo "Time: $TIME"
echo "Message: $MESSAGE"
echo ""

openclaw cron add \
  --name "$NAME" \
  --at "$TIME" \
  --message "⏰ Reminder: $MESSAGE" \
  --channel "$CHANNEL" \
  --to "$PHONE" \
  --announce \
  --delete-after-run

echo ""
echo "✅ Reminder created! Use 'openclaw cron list' to view all reminders"
