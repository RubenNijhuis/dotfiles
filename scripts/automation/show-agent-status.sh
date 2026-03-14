#!/usr/bin/env bash
# Display status for a launchd automation agent
# Usage: show-agent-status.sh <title> <agent-id> <recent-label> <recent-source> <log-glob> [lines]
set -euo pipefail

if [[ " $* " == *" --help "* ]]; then
  cat <<EOF
Usage: $0 <title> <agent-id> <recent-label> <recent-source> <log-glob> [lines]

Display launchd agent status, recent activity, and log files.

Arguments:
  title          Display title (e.g., "Backup Automation")
  agent-id       launchd agent label (e.g., "com.user.dotfiles-backup")
  recent-label   Label for the recent activity section
  recent-source  Directory (uses ls) or log file (uses tail) — ~ is expanded
  log-glob       Glob pattern for log files under ~/.local/log/
  lines          Lines to tail from log file (default: 10)
EOF
  exit 0
fi

# Filter out --no-color (accepted for CLI contract compliance)
# Reject unknown flags
args=()
for arg in "$@"; do
  if [[ "$arg" == "--no-color" ]]; then
    continue
  elif [[ "$arg" == --* ]]; then
    echo "Error: Unknown argument: $arg" >&2
    echo "Usage: $0 <title> <agent-id> <recent-label> <recent-source> <log-glob> [lines]" >&2
    exit 1
  else
    args+=("$arg")
  fi
done
set -- "${args[@]}"

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <title> <agent-id> <recent-label> <recent-source> <log-glob> [lines]" >&2
  exit 1
fi

TITLE="$1"
AGENT_ID="$2"
RECENT_LABEL="$3"
RECENT_SOURCE="$4"  # directory path or log file path (~ is expanded)
LOG_GLOB="$5"
LINES="${6:-10}"
LOG_DIR="${HOME}/.local/log/"

# Expand leading ~ to $HOME
expanded="${RECENT_SOURCE/#\~/$HOME}"

echo "${TITLE} Status:"
echo ""
echo "LaunchD Agent:"
launchctl print "gui/$(id -u)/${AGENT_ID}" >/dev/null 2>&1 && \
  echo "  ${AGENT_ID} (loaded)" || echo "  Not loaded"

echo ""
echo "${RECENT_LABEL}:"
if [[ -d "$expanded" ]]; then
  # shellcheck disable=SC2012  # ls used intentionally for human-readable timestamp display
  ls -lth "$expanded" 2>/dev/null | head -8 || echo "  No entries found"
else
  tail -"${LINES}" "$expanded" 2>/dev/null || echo "  No entries yet"
fi

echo ""
echo "Log files:"
# shellcheck disable=SC2086
ls -lh "${LOG_DIR}"${LOG_GLOB} 2>/dev/null || echo "  No logs yet"
