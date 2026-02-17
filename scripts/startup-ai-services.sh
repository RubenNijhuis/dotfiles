#!/usr/bin/env bash
# Prompt at login to optionally start AI services.
set -euo pipefail

LOG_DIR="$HOME/.local/log"
LOG_FILE="$LOG_DIR/ai-startup-selector.log"

mkdir -p "$LOG_DIR"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

start_openclaw() {
  if ! command -v openclaw >/dev/null 2>&1; then
    log "openclaw not found; skipping OpenClaw startup"
    return
  fi

  if openclaw gateway start >/dev/null 2>&1; then
    log "OpenClaw gateway started"
  else
    log "OpenClaw gateway start returned non-zero (possibly already running)"
  fi
}

start_lmstudio() {
  if ! command -v lms >/dev/null 2>&1; then
    log "lms CLI not found; skipping LM Studio startup"
    return
  fi

  if lms server start >/dev/null 2>&1; then
    log "LM Studio server started"
  else
    log "LM Studio server start returned non-zero"
  fi
}

if ! command -v osascript >/dev/null 2>&1; then
  log "osascript unavailable; starting OpenClaw and LM Studio by default"
  start_openclaw
  start_lmstudio
  exit 0
fi

CHOICE="$(osascript <<'EOF'
set dialogText to "Choose which AI services to start now:"
set dialogTitle to "AI Startup Selector"
set choice to button returned of (display dialog dialogText buttons {"Skip", "LM Studio only", "OpenClaw only", "Start both"} default button "Start both" cancel button "Skip" with title dialogTitle)
return choice
EOF
)"

log "User selected: $CHOICE"

case "$CHOICE" in
  "Start both")
    start_openclaw
    start_lmstudio
    ;;
  "OpenClaw only")
    start_openclaw
    ;;
  "LM Studio only")
    start_lmstudio
    ;;
  "Skip")
    log "No services started"
    ;;
  *)
    log "Unexpected selection '$CHOICE'; no action taken"
    ;;
esac
