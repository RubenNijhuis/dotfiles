#!/usr/bin/env bash
# Rotate old automation logs and report space freed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

LOG_DIR="$HOME/.local/log"
MAX_DAYS=30

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--days N]

Delete automation log files older than N days (default: 30).
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --days)
        MAX_DAYS="$2"
        shift 2
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  if [[ ! -d "$LOG_DIR" ]]; then
    print_info "No log directory at $LOG_DIR"
    exit 0
  fi

  print_header "Log Cleanup"

  local size_before size_after freed
  size_before=$(du -sm "$LOG_DIR" 2>/dev/null | cut -f1)

  local count
  count=$(find "$LOG_DIR" -name "*.log" -mtime +"$MAX_DAYS" 2>/dev/null | wc -l | tr -d ' ')

  rotate_logs "$LOG_DIR" "$MAX_DAYS"

  # Also clean up stale lock files
  find "$LOG_DIR" -name "*.log.lock" -mtime +1 -delete 2>/dev/null || true

  size_after=$(du -sm "$LOG_DIR" 2>/dev/null | cut -f1)
  freed=$((size_before - size_after))

  if [[ "$count" -gt 0 ]]; then
    print_success "Removed $count log file(s) older than $MAX_DAYS days"
    if [[ "$freed" -gt 0 ]]; then
      print_info "Freed ${freed}MB"
    fi
  else
    print_success "No old logs to clean up"
  fi
}

main "$@"
