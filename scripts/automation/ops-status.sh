#!/usr/bin/env bash
# Aggregate operations status for launchd-managed dotfiles automation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color]

Show launchd automation health, recent logs, and recent backup activity.
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
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

show_recent_log() {
  local label="$1"
  local log_file="$2"

  if [[ ! -f "$log_file" ]]; then
    print_dim "    $label: no log yet"
    return
  fi

  local last_modified
  last_modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$log_file" 2>/dev/null || echo "unknown")
  print_dim "    $label: $last_modified"
}

main() {
  parse_args "$@"

  print_header "Ops Status"

  print_section "Launchd agents"
  bash "$DOTFILES/scripts/automation/launchd-manager.sh" --no-color status

  print_section "Recent task logs"
  show_recent_log "backup out" "$HOME/.local/log/dotfiles-backup.out.log"
  show_recent_log "backup err" "$HOME/.local/log/dotfiles-backup.err.log"
  show_recent_log "doctor out" "$HOME/.local/log/dotfiles-doctor-launchd.out.log"
  show_recent_log "doctor err" "$HOME/.local/log/dotfiles-doctor-launchd.err.log"
  show_recent_log "repo update out" "$HOME/.local/log/repo-update.out.log"
  show_recent_log "repo update err" "$HOME/.local/log/repo-update.err.log"

  print_section "Backup recency"
  latest_backup=$(find "$HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1 || true)
  if [[ -n "${latest_backup:-}" ]]; then
    print_success "Latest backup: $(basename "$latest_backup")"
  else
    print_warning "No backups found in ~/.dotfiles-backup"
  fi
}

main "$@"
