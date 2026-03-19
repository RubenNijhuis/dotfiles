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

  if [[ "$log_file" == *.err.log ]]; then
    if [[ -s "$log_file" ]]; then
      print_warning "  $label: $last_modified (has errors)"
    else
      print_dim "    $label: $last_modified (clean)"
    fi
  elif [[ "$log_file" == *.out.log ]]; then
    local last_line
    last_line=$(tail -1 "$log_file" 2>/dev/null || true)
    if [[ "$last_line" =~ (✓|passed|success|complete) ]]; then
      print_success "  $label: $last_modified"
    elif [[ "$last_line" =~ (✗|error|fail) ]]; then
      print_error "  $label: $last_modified"
    else
      print_dim "    $label: $last_modified"
    fi
  else
    print_dim "    $label: $last_modified"
  fi
}

main() {
  parse_args "$@"

  # Source agent registry for log file paths
  source "$DOTFILES/scripts/automation/launchd/common.sh"

  print_header "Ops Status"

  print_section "Launchd agents"
  bash "$DOTFILES/scripts/automation/launchd-manager.sh" --no-color status

  print_section "Recent task logs"
  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name _desc <<< "$agent_info"
    local out_log err_log
    out_log="$(agent_log_file "$name")"
    err_log="${out_log%.out.log}.err.log"
    show_recent_log "$name out" "$out_log"
    show_recent_log "$name err" "$err_log"
  done

  print_section "Backup recency"
  latest_backup=$(find "$HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1 || true)
  if [[ -n "${latest_backup:-}" ]]; then
    print_success "Latest backup: $(basename "$latest_backup")"
  else
    print_warning "No backups found in ~/.dotfiles-backup"
  fi
}

main "$@"
