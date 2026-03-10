#!/usr/bin/env bash
# Start LM Studio server and load the default model.
# SCRIPT_VISIBILITY: launchd-internal
set -euo pipefail

LOG_FILE="$HOME/.local/log/lmstudio-server.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

LMS="${HOME}/.lmstudio/bin/lms"
if [[ ! -x "$LMS" ]]; then
  log "ERROR: lms CLI not found at $LMS"
  exit 1
fi

# Default model can be overridden via env var (set in local.sh)
MODEL="${LMSTUDIO_DEFAULT_MODEL:-qwen3.5-2b}"
PORT="${LMSTUDIO_PORT:-1234}"

# Check if server is already running
if "$LMS" server status 2>/dev/null | grep -q "running"; then
  log "Server already running"
else
  log "Starting LM Studio server on port $PORT"
  "$LMS" server start --port "$PORT" 2>>"$LOG_FILE" || {
    log "ERROR: Failed to start server"
    exit 1
  }
  # Give the server a moment to initialize
  sleep 3
  log "Server started"
fi

# Check if model is already loaded
if "$LMS" ps 2>/dev/null | grep -q "$MODEL"; then
  log "Model $MODEL already loaded"
else
  log "Loading model: $MODEL"
  "$LMS" load "$MODEL" 2>>"$LOG_FILE" || {
    log "ERROR: Failed to load model $MODEL"
    exit 1
  }
  log "Model loaded"
fi

log "LM Studio ready (port=$PORT, model=$MODEL)"
