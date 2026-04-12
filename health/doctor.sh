#!/usr/bin/env bash
# Comprehensive system health check for dotfiles setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

# Handle --help and unknown flags before the version gate so CLI contract
# tests pass on bash 3.x (CI runners use macOS stock bash 3.2).
_doctor_usage() {
  cat <<USAGE
Usage: $0 [--help] [--quick] [--full] [--status] [--section <name>] [--no-color]

Comprehensive system health check for dotfiles setup.

Options:
  --quick             Run a reduced set of checks (skip slow network/brew checks)
  --full              Run the full check set (default)
  --status            Show quick actionable system status summary
  --section <name>    Run only the specified check section
  --no-color          Disable colored output
  --help, -h          Show this help message

Sections:
  stow, ssh, gpg, git, shell, developer, runtime, profile,
  launchd, homebrew, backup, biome, tmux, neovim, starship, shell-perf
USAGE
}

for _arg in "$@"; do
  case "$_arg" in
    --help|-h) _doctor_usage; exit 0 ;;
    --quick|--status|--full|--no-color) ;;
    --section) ;;
    --*) echo "Unknown argument: $_arg" >&2; _doctor_usage >&2; exit 1 ;;
  esac
done

require_bash_version 4 "doctor.sh"

QUICK_MODE=false
STATUS_MODE=false
SECTION=""
export DOTFILES QUICK_MODE

usage() { _doctor_usage; }

validate_section() {
  case "$1" in
    stow|ssh|gpg|git|shell|developer|runtime|profile|launchd|homebrew|backup|biome|tmux|neovim|starship|shell-perf)
      return 0
      ;;
    *)
      print_error "Unknown section: $1"
      print_info "Valid sections: stow, ssh, gpg, git, shell, developer, runtime, profile, launchd, homebrew, backup, biome, tmux, neovim, starship, shell-perf"
      return 1
      ;;
  esac
}

parse_args() {
  # --help is handled before require_bash_version for CI compatibility
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick)
        QUICK_MODE=true
        shift
        ;;
      --full)
        QUICK_MODE=false
        shift
        ;;
      --status)
        STATUS_MODE=true
        shift
        ;;
      --section)
        if [[ $# -lt 2 ]]; then
          usage
          exit 1
        fi
        SECTION="$2"
        shift 2
        ;;
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

  if [[ -n "$SECTION" ]]; then
    validate_section "$SECTION" || exit 1
  fi
}

# Counters
PASSED=0
WARNINGS=0
ERRORS=0

# Suggestions array
declare -a SUGGESTIONS=()

# Args: check_name, status (0=pass, 1=warning, 2=error), message
record_result() {
  local name="$1"
  local status="$2"
  local message="$3"

  case "$status" in
    0)
      printf '  %s✓%s %s%s%s\n' "${GREEN}" "${NC}" "${BOLD}" "$name" "${NC}"
      PASSED=$((PASSED + 1))
      ;;
    1)
      printf '  %s⚠%s %s%s%s\n' "${YELLOW}" "${NC}" "${BOLD}" "$name" "${NC}"
      WARNINGS=$((WARNINGS + 1))
      ;;
    2)
      printf '  %s✗%s %s%s%s\n' "${RED}" "${NC}" "${BOLD}" "$name" "${NC}"
      ERRORS=$((ERRORS + 1))
      ;;
  esac
  # Print details indented under the check name
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}" # trim leading whitespace
    [[ -z "$line" ]] && continue
    printf '    %s%s%s\n' "${DIM}" "$line" "${NC}"
  done <<< "$(printf '%b' "$message")"
}

add_suggestion() {
  SUGGESTIONS+=("$1")
}

record_issue_count_result() {
  local name="$1"
  local issues="$2"
  local nonzero_status="$3"
  local message="$4"

  if [[ "$issues" -eq 0 ]]; then
    record_result "$name" 0 "$message"
  else
    record_result "$name" "$nonzero_status" "$message"
  fi
}

should_run() {
  local section_name="$1"
  [[ -z "$SECTION" || "$SECTION" == "$section_name" ]]
}

run_checks() {
  printf '  %s%s── Core ──%s\n' "${DIM}" "${BLUE}" "${NC}"
  if should_run stow; then check_stow; fi
  if should_run ssh; then check_ssh; fi
  if should_run gpg; then check_gpg; fi
  if should_run git; then check_git; fi
  if should_run shell; then check_shell; fi

  printf '\n  %s%s── System ──%s\n' "${DIM}" "${BLUE}" "${NC}"
  if should_run developer; then check_developer; fi
  if should_run runtime; then check_runtime; fi
  if should_run profile; then check_profile_contract; fi
  if should_run launchd; then check_launchd; fi
  if should_run homebrew; then check_homebrew; fi
  if should_run backup; then check_backup_system; fi
  if should_run shell-perf; then check_shell_perf; fi

  printf '\n  %s%s── Tools ──%s\n' "${DIM}" "${BLUE}" "${NC}"
  if should_run biome; then check_biome; fi
  if should_run tmux; then check_tmux; fi
  if should_run neovim; then check_neovim; fi
  if should_run starship; then check_starship; fi
}

print_run_context() {
  local mode_label="full"
  [[ "$QUICK_MODE" == true ]] && mode_label="quick"
  [[ -n "$SECTION" ]] && mode_label="section:$SECTION"

  print_section "Overview"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
  print_status_row "Mode" info "$mode_label"
  print_status_row "Scope" info "machine health, tooling, and automation checks"
}

print_summary() {
  printf '\n'
  local total=$((PASSED + WARNINGS + ERRORS))
  local overall_status="ok"
  local overall_detail="everything looks healthy"
  if [[ $ERRORS -gt 0 ]]; then
    overall_status="error"
    overall_detail="$ERRORS error(s) need attention"
  elif [[ $WARNINGS -gt 0 ]]; then
    overall_status="warn"
    overall_detail="$WARNINGS warning(s) worth checking"
  fi

  print_section "Summary"
  print_status_row "Overall" "$overall_status" "$overall_detail"
  print_status_row "Checks" info "$total total"
  print_status_row "Passed" ok "$PASSED"
  print_status_row "Warnings" warn "$WARNINGS"
  print_status_row "Errors" error "$ERRORS"

  if [[ ${#SUGGESTIONS[@]} -gt 0 ]]; then
    local next_steps=()
    declare -A _seen_suggestions=()
    local suggestion
    for suggestion in "${SUGGESTIONS[@]}"; do
      if [[ -z "${_seen_suggestions[$suggestion]:-}" ]]; then
        next_steps+=("$suggestion")
        _seen_suggestions[$suggestion]=1
      fi
    done
    print_next_steps "${next_steps[@]}"
  else
    print_next_steps "No action needed."
  fi

  printf '\n'
}

# ── Status mode ──────────────────────────────────────────────────────
# Quick actionable summary: doctor health, stow, launchd, backup, docs.

status_check_doctor() {
  local output exit_code=0
  output=$(bash "$SCRIPT_DIR/doctor.sh" --quick --no-color 2>&1) || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    local count
    count=$(echo "$output" | grep -c "✓" || echo "0")
    print_status_row "Doctor" ok "$count quick checks passed"
  else
    local warnings errors
    warnings=$(echo "$output" | grep -c "⚠" || echo "0")
    errors=$(echo "$output" | grep -c "✗" || echo "0")
    if [[ $errors -gt 0 ]]; then
      print_status_row "Doctor" error "$errors errors, $warnings warnings"
    else
      print_status_row "Doctor" warn "$warnings warnings"
    fi
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_stow() {
  local stow_dir="$DOTFILES/config"
  local total broken
  total=$(find "$stow_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | xargs)
  broken=$(count_broken_symlinks "$HOME")

  if [[ $broken -eq 0 ]]; then
    print_status_row "Stow" ok "$total packages, no broken symlinks"
  else
    print_status_row "Stow" error "$broken broken symlinks"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_launchd() {
  LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"
  local managed=0 loaded=0
  while IFS= read -r agent_info; do
    IFS=':' read -r name _desc <<< "$agent_info"
    managed=$((managed + 1))
    if is_agent_loaded "$name"; then
      loaded=$((loaded + 1))
    fi
  done < <(profile_agent_infos)

  if [[ $loaded -eq $managed ]]; then
    print_status_row "Launchd" ok "$loaded/$managed agents loaded"
  elif [[ $loaded -gt 0 ]]; then
    print_status_row "Launchd" warn "$loaded/$managed agents loaded"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  else
    print_status_row "Launchd" warn "no agents loaded"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_backup() {
  local backup_dir="$HOME/.dotfiles-backup"
  if [[ ! -d "$backup_dir" ]]; then
    print_status_row "Backup" warn "no backups found"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
    return
  fi

  local latest
  latest=$(find "$backup_dir" -maxdepth 1 -type d -name "202*" | sort -r | head -n1)
  if [[ -z "$latest" ]]; then
    print_status_row "Backup" warn "no backups found"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
    return
  fi

  local age_days
  age_days=$(( ($(date +%s) - $(stat -f %m "$latest")) / 86400 ))
  if [[ $age_days -le 7 ]]; then
    print_status_row "Backup" ok "${age_days}d ago"
  else
    print_status_row "Backup" warn "${age_days}d ago (stale)"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_docs() {
  if bash "$DOTFILES/ops/generate-cli-reference.sh" --check --no-color >/dev/null 2>&1; then
    print_status_row "Docs" ok "generated reference is current"
  else
    print_status_row "Docs" warn "generated reference is stale"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

run_status() {
  source "$SCRIPT_DIR/../lib/env.sh"
  dotfiles_load_env "$DOTFILES"

  STATUS_ISSUES=0
  print_header "System Status"
  print_dim "Quick readout for the machine state that needs action today."
  printf '\n'
  print_section "Today"

  status_check_doctor
  status_check_stow
  status_check_launchd
  status_check_backup
  status_check_docs

  print_section "Summary"
  if [[ $STATUS_ISSUES -eq 0 ]]; then
    print_status_row "Overall" ok "all clear"
    print_next_steps "No action needed."
  else
    print_status_row "Overall" warn "$STATUS_ISSUES item(s) need attention"
    print_next_steps \
      "Run: make doctor" \
      "Run: make ops-status" \
      "Run: make automation-setup if launchd agents are missing" \
      "Run: make backup if backup status is stale"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────

main() {
  parse_args "$@"

  if $STATUS_MODE; then
    run_status
    return
  fi

  source "$SCRIPT_DIR/checks/core.sh"
  source "$SCRIPT_DIR/checks/system.sh"
  source "$SCRIPT_DIR/checks/editor.sh"

  print_header "System Health Check"
  print_dim "Use this when you want a deeper read on machine health, config drift, and tooling."
  printf '\n'
  print_run_context
  run_checks
  print_summary

  if [[ $ERRORS -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
