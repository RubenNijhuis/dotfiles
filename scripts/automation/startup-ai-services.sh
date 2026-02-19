#!/usr/bin/env bash
# Prompt at login to optionally start AI services.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

LOG_DIR="$HOME/.local/log"
LOG_FILE="$LOG_DIR/ai-startup-selector.log"
NON_INTERACTIVE=false
POLICY="${AI_STARTUP_POLICY:-prompt}"

mkdir -p "$LOG_DIR"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--yes] [--policy <prompt|both|openclaw|lmstudio|skip>]

Prompt at login to start OpenClaw and/or LM Studio.

Options:
  --yes                       Non-interactive mode (uses --policy).
  --policy <value>            Startup mode, defaults to env AI_STARTUP_POLICY or prompt.
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --yes)
        NON_INTERACTIVE=true
        shift
        ;;
      --policy)
        if [[ $# -lt 2 ]]; then
          echo "Missing value for --policy" >&2
          usage
          exit 1
        fi
        POLICY="$2"
        shift 2
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  case "$POLICY" in
    prompt|both|openclaw|lmstudio|skip) ;;
    *)
      echo "Invalid --policy: $POLICY" >&2
      usage
      exit 1
      ;;
  esac
}

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

run_policy() {
  case "$1" in
    both)
    start_openclaw
    start_lmstudio
    ;;
    openclaw)
    start_openclaw
    ;;
    lmstudio)
    start_lmstudio
    ;;
    skip)
    log "No services started"
    ;;
  esac
}

main() {
  parse_args "$@"

  if $NON_INTERACTIVE || [[ "$POLICY" != "prompt" ]]; then
    run_policy "$POLICY"
    exit 0
  fi

  if ! command -v osascript >/dev/null 2>&1; then
    log "osascript unavailable; defaulting to policy 'both'"
    run_policy "both"
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
    "Start both") run_policy "both" ;;
    "OpenClaw only") run_policy "openclaw" ;;
    "LM Studio only") run_policy "lmstudio" ;;
    "Skip") run_policy "skip" ;;
    *) log "Unexpected selection '$CHOICE'; no action taken" ;;
  esac
}

main "$@"
