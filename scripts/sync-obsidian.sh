#!/usr/bin/env bash
# Sync Obsidian vault to remote repository
# Runs daily to backup local changes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

VAULT_PATH="$HOME/Developer/personal/projects/obsidian-store"
LOG_FILE="$HOME/.local/log/obsidian-sync.log"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [path]

Sync an Obsidian git repository (default: ~/Developer/personal/projects/obsidian-store).
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        if [[ "${1#-}" != "$1" ]]; then
          print_error "Unknown argument: $1"
          usage
          exit 1
        fi
        VAULT_PATH="$1"
        shift
        ;;
    esac
  done
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

main() {
  parse_args "$@"
  require_cmd "git" "Install Git first: brew install git" >/dev/null || {
    log "ERROR: Git is required"
    exit 1
  }

  mkdir -p "$(dirname "$LOG_FILE")"

  if [[ ! -d "$VAULT_PATH" ]]; then
    log "ERROR: Vault directory not found at $VAULT_PATH"
    exit 1
  fi

  cd "$VAULT_PATH"

  if git diff-index --quiet HEAD -- 2>/dev/null; then
    log "No changes to sync"
    exit 0
  fi

  log "Starting Obsidian vault sync..."

  git add -A

  if git diff-index --quiet --cached HEAD -- 2>/dev/null; then
    log "No staged changes after git add"
    exit 0
  fi

  local commit_msg
  commit_msg="Automated vault backup: $(date '+%Y-%m-%d %H:%M:%S')"
  git commit -m "$commit_msg"

  if git push; then
    log "Successfully synced Obsidian vault"
  else
    log "ERROR: Failed to push changes"
    exit 1
  fi
}

main "$@"
