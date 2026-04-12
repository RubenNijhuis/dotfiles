#!/usr/bin/env bash
# Aggregate operations status for launchd-managed dotfiles automation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/cli.sh"

# shellcheck disable=SC2329
usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Show launchd automation health, recent logs, and recent backup activity.
EOF
}

log_timestamp() {
  local log_file="$1"
  if [[ -f "$log_file" ]]; then
    stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$log_file" 2>/dev/null || echo "unknown"
  else
    echo "no log"
  fi
}

log_status() {
  local log_file="$1"
  if [[ ! -f "$log_file" ]]; then
    echo "warn|no log yet"
    return
  fi

  if [[ "$log_file" == *.err.log ]]; then
    if [[ -s "$log_file" ]]; then
      echo "error|errors recorded"
    else
      echo "ok|clean"
    fi
    return
  fi

  local last_line
  last_line=$(tail -1 "$log_file" 2>/dev/null || true)
  if [[ "$last_line" =~ (✓|passed|success|complete) ]]; then
    echo "ok|healthy"
  elif [[ "$last_line" =~ (✗|error|fail) ]]; then
    echo "error|failed"
  else
    echo "info|awaiting signal"
  fi
}

render_agent_dashboard() {
  print_section "Automation Dashboard"

  local loaded_count=0 warn_count=0 error_count=0
  local agent_info name desc loaded_state out_log err_log
  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name desc <<< "$agent_info"
    out_log="$(agent_log_file "$name")"
    err_log="$(agent_error_log_file "$name")"

    if is_agent_loaded "$name"; then
      loaded_state="loaded"
      loaded_count=$((loaded_count + 1))
    else
      loaded_state="not loaded"
      warn_count=$((warn_count + 1))
    fi

    local out_status out_detail err_status err_detail
    IFS='|' read -r out_status out_detail <<< "$(log_status "$out_log")"
    IFS='|' read -r err_status err_detail <<< "$(log_status "$err_log")"

    if [[ "$out_status" == "error" || "$err_status" == "error" ]]; then
      error_count=$((error_count + 1))
    elif [[ "$loaded_state" != "loaded" || "$out_status" == "warn" || "$err_status" == "warn" ]]; then
      warn_count=$((warn_count + 1))
    fi

    print_status_row "$name" "${out_status}" "$loaded_state | out $(log_timestamp "$out_log") ($out_detail) | err $(log_timestamp "$err_log") ($err_detail)"
    print_dim "    $desc"
  done

  printf '\n'
  print_status_row "Loaded agents" info "${loaded_count}/${#AGENTS[@]}"
  print_status_row "Warnings" warn "$warn_count"
  print_status_row "Errors" error "$error_count"
}

render_attention() {
  print_section "Attention"

  local alerts=0
  local agent_info name out_log err_log out_status out_detail err_status err_detail
  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name _desc <<< "$agent_info"
    out_log="$(agent_log_file "$name")"
    err_log="$(agent_error_log_file "$name")"
    IFS='|' read -r out_status out_detail <<< "$(log_status "$out_log")"
    IFS='|' read -r err_status err_detail <<< "$(log_status "$err_log")"

    if ! is_agent_loaded "$name"; then
      print_bullet "$name is not loaded"
      alerts=$((alerts + 1))
    fi
    if [[ "$out_status" == "error" ]]; then
      print_bullet "$name out log indicates: $out_detail"
      alerts=$((alerts + 1))
    fi
    if [[ "$err_status" == "error" ]]; then
      print_bullet "$name err log indicates: $err_detail"
      alerts=$((alerts + 1))
    fi
  done

  if [[ $alerts -eq 0 ]]; then
    print_bullet "No immediate action needed."
  fi
}

main() {
  parse_standard_args usage "$@"

  # Source agent registry for AGENTS array and agent_log_file()
  LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"

  print_header "Ops Status"
  print_dim "A quick dashboard for recurring automations, recent runs, and backup freshness."
  printf '\n'
  render_agent_dashboard
  render_attention

  print_section "Backup recency"
  local latest_backup
  latest_backup=$(find "$HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1 || true)
  if [[ -n "${latest_backup:-}" ]]; then
    print_status_row "Latest backup" ok "$(basename "$latest_backup")"
  else
    print_status_row "Latest backup" warn "none found"
  fi

  print_next_steps "Run: make automation-setup if agents are missing" "Run: make doctor for a full health pass"
}

main "$@"
