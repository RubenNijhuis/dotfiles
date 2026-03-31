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
Usage: $0 [--help] [--quick] [--status] [--section <name>] [--no-color]

Comprehensive system health check for dotfiles setup.

Options:
  --quick             Run a reduced set of checks (skip slow network/brew checks)
  --status            Show quick actionable system status summary
  --section <name>    Run only the specified check section
  --no-color          Disable colored output
  --help, -h          Show this help message

Sections:
  stow, ssh, gpg, git, shell, developer, runtime,
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

should_run() {
  local section_name="$1"
  [[ -z "$SECTION" || "$SECTION" == "$section_name" ]]
}

run_checks() {
  printf '  '; print_section "Core"
  should_run stow && check_stow
  should_run ssh && check_ssh
  should_run gpg && check_gpg
  should_run git && check_git
  should_run shell && check_shell

  printf '\n  '; print_section "System"
  should_run developer && check_developer
  should_run runtime && check_runtime
  should_run launchd && check_launchd
  should_run homebrew && check_homebrew
  should_run backup && check_backup_system
  should_run shell-perf && check_shell_perf

  printf '\n  '; print_section "Tools"
  should_run biome && check_biome
  should_run tmux && check_tmux
  should_run neovim && check_neovim
  should_run starship && check_starship
}

print_summary() {
  printf '\n'
  local total=$((PASSED + WARNINGS + ERRORS))
  local parts=()
  parts+=("${GREEN}${PASSED} passed${NC}")
  [[ $WARNINGS -gt 0 ]] && parts+=("${YELLOW}${WARNINGS} warning(s)${NC}")
  [[ $ERRORS -gt 0 ]] && parts+=("${RED}${ERRORS} error(s)${NC}")

  local summary=""
  for i in "${!parts[@]}"; do
    [[ $i -gt 0 ]] && summary+=", "
    summary+="${parts[$i]}"
  done
  printf '  %s%s/%s checks:%s %b\n' "${BOLD}" "$total" "$total" "${NC}" "$summary"

  if [[ ${#SUGGESTIONS[@]} -gt 0 ]]; then
    printf '\n'
    printf '  %s%sSuggested fixes:%s\n' "${BOLD}" "${YELLOW}" "${NC}"
    # Deduplicate suggestions while preserving order
    declare -A _seen_suggestions=()
    for suggestion in "${SUGGESTIONS[@]}"; do
      if [[ -z "${_seen_suggestions[$suggestion]:-}" ]]; then
        printf '    %s→%s %s\n' "${YELLOW}" "${NC}" "$suggestion"
        _seen_suggestions[$suggestion]=1
      fi
    done
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
    count=$(echo "$output" | grep -c "^✓" || echo "0")
    print_success "Health checks: $count passed"
  else
    local warnings errors
    warnings=$(echo "$output" | grep -c "^⚠" || echo "0")
    errors=$(echo "$output" | grep -c "^✗" || echo "0")
    if [[ $errors -gt 0 ]]; then
      print_error "Health checks: $errors errors, $warnings warnings"
    else
      print_warning "Health checks: $warnings warnings"
    fi
    print_dim "  → Run: make doctor"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_stow() {
  local stow_dir="$DOTFILES/config"
  local total broken
  total=$(find "$stow_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | xargs)
  broken=$(count_broken_symlinks "$HOME")

  if [[ $broken -eq 0 ]]; then
    print_success "Stow: $total packages, no broken symlinks"
  else
    print_error "Stow: $broken broken symlinks"
    print_dim "  → Run: make unstow && make stow"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_launchd() {
  LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"
  local managed=0 loaded=0
  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name _desc <<< "$agent_info"
    managed=$((managed + 1))
    if is_agent_loaded "$name"; then
      loaded=$((loaded + 1))
    fi
  done

  if [[ $loaded -eq $managed ]]; then
    print_success "LaunchD: $loaded/$managed agents loaded"
  elif [[ $loaded -gt 0 ]]; then
    print_warning "LaunchD: $loaded/$managed agents loaded"
    print_dim "  → $((managed - loaded)) not loaded. Run: make automation-setup"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  else
    print_warning "LaunchD: no agents loaded"
    print_dim "  → Run: make automation-setup"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_backup() {
  local backup_dir="$HOME/.dotfiles-backup"
  if [[ ! -d "$backup_dir" ]]; then
    print_warning "Backup: no backups found"
    print_dim "  → Run: make backup"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
    return
  fi

  local latest
  latest=$(find "$backup_dir" -maxdepth 1 -type d -name "202*" | sort -r | head -n1)
  if [[ -z "$latest" ]]; then
    print_warning "Backup: no backups found"
    print_dim "  → Run: make backup"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
    return
  fi

  local age_days
  age_days=$(( ($(date +%s) - $(stat -f %m "$latest")) / 86400 ))
  if [[ $age_days -le 7 ]]; then
    print_success "Backup: ${age_days}d ago"
  else
    print_warning "Backup: ${age_days}d ago (stale)"
    print_dim "  → Run: make backup"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

status_check_docs() {
  if bash "$DOTFILES/ops/generate-cli-reference.sh" --check --no-color >/dev/null 2>&1; then
    print_success "Docs: up to date"
  else
    print_warning "Docs: generated reference is stale"
    print_dim "  → Run: make docs-regen"
    STATUS_ISSUES=$((STATUS_ISSUES + 1))
  fi
}

run_status() {
  source "$SCRIPT_DIR/../lib/env.sh"
  dotfiles_load_env "$DOTFILES"

  STATUS_ISSUES=0
  print_header "System Status"

  status_check_doctor
  status_check_stow
  status_check_launchd
  status_check_backup
  status_check_docs

  printf '\n'
  if [[ $STATUS_ISSUES -eq 0 ]]; then
    print_success "All clear"
  else
    print_dim "$STATUS_ISSUES item(s) need attention"
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
  run_checks
  print_summary

  if [[ $ERRORS -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
