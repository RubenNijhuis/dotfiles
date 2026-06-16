#!/usr/bin/env bash
# Comprehensive system health check for dotfiles setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
# shellcheck source=../lib/parallel.sh
source "$SCRIPT_DIR/../lib/parallel.sh"

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
    stow|ssh|gpg|git|shell|developer|runtime|launchd|homebrew|backup|biome|tmux|neovim|starship|shell-perf)
      return 0
      ;;
    *)
      print_error "Unknown section: $1"
      print_info "Valid sections: stow, ssh, gpg, git, shell, developer, runtime, launchd, homebrew, backup, biome, tmux, neovim, starship, shell-perf"
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
    if [[ -n "$line" ]]; then
      printf '    %s%s%s\n' "${DIM}" "$line" "${NC}"
    fi
  done <<< "$(printf '%b' "$message")"
  return 0
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

# Doctor checks mutate shared state (PASSED/WARNINGS/ERRORS counters and the
# SUGGESTIONS array) via record_result/add_suggestion. To run them in parallel
# we wrap each check in a subshell that resets that state, runs the check,
# and writes the resulting deltas to a sidecar .state file. The parent then
# folds those deltas back into its own counters during replay.
_doctor_tmp=""

# Run a single check function with its counter state captured to .state.
# Intended to be invoked via parallel_spawn — stdout is already redirected.
_doctor_run_check() {
  # Use a deliberately-namespaced local — check functions (e.g. check_launchd)
  # use `name` as a loop var; bash dynamic scoping would let them clobber ours.
  local __doctor_check_fn="$1"
  # shellcheck disable=SC2030  # Subshell mutation is intentional; values flow through .state.
  PASSED=0
  # shellcheck disable=SC2030
  WARNINGS=0
  # shellcheck disable=SC2030
  ERRORS=0
  # shellcheck disable=SC2030
  declare -a SUGGESTIONS=()
  "$__doctor_check_fn"
  {
    printf '%d|%d|%d\n' "$PASSED" "$WARNINGS" "$ERRORS"
    local s
    for s in "${SUGGESTIONS[@]}"; do
      printf 'SUGGEST:%s\n' "$s"
    done
  } > "$_doctor_tmp/$__doctor_check_fn.state"
}

run_section_parallel() {
  local section_label="$1"; shift
  local checks=("$@")
  [[ ${#checks[@]} -eq 0 ]] && return 0

  printf '%s\n' "$section_label"

  local check
  for check in "${checks[@]}"; do
    parallel_spawn "$_doctor_tmp" "$check" _doctor_run_check "$check"
  done
  parallel_wait

  parallel_replay "$_doctor_tmp" "${checks[@]}"

  # Fold each check's counter deltas and suggestions back into parent state.
  for check in "${checks[@]}"; do
    local p w e
    IFS='|' read -r p w e < "$_doctor_tmp/$check.state"
    # shellcheck disable=SC2031  # Updated via state file, not a leaked subshell scope.
    PASSED=$((PASSED + p))
    # shellcheck disable=SC2031
    WARNINGS=$((WARNINGS + w))
    # shellcheck disable=SC2031
    ERRORS=$((ERRORS + e))
    while IFS= read -r line; do
      if [[ "$line" == SUGGEST:* ]]; then
        # shellcheck disable=SC2031
        SUGGESTIONS+=("${line#SUGGEST:}")
      fi
    done < "$_doctor_tmp/$check.state"
  done
}

run_checks() {
  _doctor_tmp="$(parallel_tmpdir doctor)"
  [[ -z "${DOCTOR_KEEP_TMP:-}" ]] && trap 'rm -rf "${_doctor_tmp:-}"' EXIT

  local core=() system=() tools=()
  should_run stow      && core+=(check_stow)
  should_run ssh       && core+=(check_ssh)
  should_run gpg       && core+=(check_gpg)
  should_run git       && core+=(check_git)
  should_run shell     && core+=(check_shell)
  run_section_parallel "$(printf '  %s%s── Core ──%s\n' "${DIM}" "${BLUE}" "${NC}")" "${core[@]}"

  should_run developer && system+=(check_developer)
  should_run runtime   && system+=(check_runtime)
  should_run launchd   && system+=(check_launchd)
  should_run homebrew  && system+=(check_homebrew)
  should_run backup    && system+=(check_backup_system)
  should_run shell-perf && system+=(check_shell_perf)
  run_section_parallel "$(printf '\n  %s%s── System ──%s\n' "${DIM}" "${BLUE}" "${NC}")" "${system[@]}"

  should_run biome    && tools+=(check_biome)
  should_run tmux     && tools+=(check_tmux)
  should_run neovim   && tools+=(check_neovim)
  should_run starship && tools+=(check_starship)
  run_section_parallel "$(printf '\n  %s%s── Tools ──%s\n' "${DIM}" "${BLUE}" "${NC}")" "${tools[@]}"
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
  # Renamed concept: dotfiles are now managed by chezmoi, but the function
  # name is preserved to avoid a wider rename in the status pipeline.
  if ! command -v chezmoi >/dev/null 2>&1; then
    print_status_row "chezmoi" error "not installed"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
    return
  fi
  local pending
  pending=$(chezmoi status 2>/dev/null | wc -l | xargs)
  if [[ "$pending" -eq 0 ]]; then
    print_status_row "chezmoi" ok "source state in sync"
  else
    print_status_row "chezmoi" warn "$pending entries differ — run: chezmoi apply"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_launchd() {
  LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"
  local managed=0 loaded=0
  local _agent_entry _agent_name _agent_desc
  while IFS= read -r _agent_entry; do
    IFS=':' read -r _agent_name _agent_desc <<< "$_agent_entry"
    managed=$((managed + 1))
    if is_agent_loaded "$_agent_name"; then
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
  local ref="$DOTFILES/docs/reference/cli.md"
  if [[ -f "$ref" ]]; then
    print_status_row "Docs" ok "CLI reference present"
  else
    print_status_row "Docs" warn "CLI reference missing — run: make docs-regen"
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
