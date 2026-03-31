#!/usr/bin/env bash
# Weekly automation digest — summarize the past 7 days of automation runs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/cli.sh"
LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Summarize automation health over the past 7 days and send a notification.
EOF
}

# Count log entries from the past N days matching a pattern.
count_log_entries() {
  local log_file="$1"
  local days="$2"
  local pattern="$3"
  local cutoff
  cutoff=$(date -v-"${days}"d '+%Y-%m-%d' 2>/dev/null || date -d "$days days ago" '+%Y-%m-%d' 2>/dev/null || echo "0000-00-00")

  if [[ ! -f "$log_file" ]]; then
    echo 0
    return
  fi

  local count=0
  while IFS= read -r line; do
    # Extract date from log lines like [2026-03-20 09:00:01]
    local log_date
    log_date=$(echo "$line" | grep -oE '^\[?[0-9]{4}-[0-9]{2}-[0-9]{2}' | tr -d '[' || true)
    if [[ -n "$log_date" ]] && [[ "$log_date" > "$cutoff" || "$log_date" == "$cutoff" ]]; then
      if echo "$line" | grep -qiE "$pattern"; then
        count=$((count + 1))
      fi
    fi
  done < "$log_file"

  echo "$count"
}

main() {
  parse_standard_args usage "$@"

  print_header "Weekly Automation Digest"

  local total_ok=0
  local total_fail=0
  local summary_lines=()

  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name _desc <<< "$agent_info"
    local log_file
    log_file="$(agent_log_file "$name")"

    if [[ ! -f "$log_file" ]]; then
      summary_lines+=("$name: no logs")
      continue
    fi

    local ok fail
    ok=$(count_log_entries "$log_file" 7 "exit=0|success|complete|✓|passed")
    fail=$(count_log_entries "$log_file" 7 "exit=[1-9]|error|fail|✗")

    if [[ $fail -gt 0 ]]; then
      print_warning "$name: $ok ok, $fail failed (past 7 days)"
      summary_lines+=("$name: ${ok}ok/${fail}fail")
    elif [[ $ok -gt 0 ]]; then
      print_success "$name: $ok successful runs (past 7 days)"
      summary_lines+=("$name: ${ok}ok")
    else
      print_dim "  $name: no recent activity"
      summary_lines+=("$name: inactive")
    fi

    total_ok=$((total_ok + ok))
    total_fail=$((total_fail + fail))
  done

  printf '\n'

  if [[ $total_fail -gt 0 ]]; then
    print_error "Total: $total_ok ok, $total_fail failed"
    notify "Weekly Digest" "$total_fail automation failure(s) this week"
  else
    print_success "Total: $total_ok successful runs, 0 failures"
    notify "Weekly Digest" "All automations healthy ($total_ok runs)"
  fi
}

main "$@"
