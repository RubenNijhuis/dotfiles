#!/usr/bin/env bash
# Comprehensive system health check for dotfiles setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared output helpers; respects --no-color when present in argv.
source "$SCRIPT_DIR/../lib/output.sh" "$@"

QUICK_MODE=false
SECTION=""
export DOTFILES QUICK_MODE

usage() {
  echo "Usage: $0 [--help] [--quick] [--section <name>] [--no-color]"
}

validate_section() {
  case "$1" in
    stow|ssh|gpg|git|shell|developer|runtime|launchd|homebrew|vscode|backup|biome)
      return 0
      ;;
    *)
      echo "Unknown section: $1"
      echo "Valid sections: stow, ssh, gpg, git, shell, developer, runtime, launchd, homebrew, vscode, backup, biome"
      return 1
      ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick)
        QUICK_MODE=true
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
      --help|-h)
        usage
        exit 0
        ;;
      --no-color)
        shift
        ;;
      *)
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
      print_success "$name"
      printf '  %b\n' "$message"
      PASSED=$((PASSED + 1))
      ;;
    1)
      print_warning "$name"
      printf '  ⚠ %b\n' "$message"
      WARNINGS=$((WARNINGS + 1))
      ;;
    2)
      print_error "$name"
      printf '  ✗ %b\n' "$message"
      ERRORS=$((ERRORS + 1))
      ;;
  esac
  printf '\n'
}

add_suggestion() {
  SUGGESTIONS+=("$1")
}

should_run() {
  local section_name="$1"
  [[ -z "$SECTION" || "$SECTION" == "$section_name" ]]
}

run_checks() {
  should_run stow && check_stow
  should_run ssh && check_ssh
  should_run gpg && check_gpg
  should_run git && check_git
  should_run shell && check_shell
  should_run developer && check_developer
  should_run runtime && check_runtime
  should_run launchd && check_launchd
  should_run homebrew && check_homebrew
  should_run vscode && check_vscode_config
  should_run backup && check_backup_system
  should_run biome && check_biome
}

print_summary() {
  print_section "Summary"
  print_key_value "Passed" "$PASSED checks"
  if [[ $WARNINGS -gt 0 ]]; then
    print_key_value "Warnings" "$WARNINGS"
  fi
  if [[ $ERRORS -gt 0 ]]; then
    print_key_value "Errors" "$ERRORS"
  fi
  echo ""

  if [[ ${#SUGGESTIONS[@]} -gt 0 ]]; then
    print_section "Suggested fixes"
    for suggestion in "${SUGGESTIONS[@]}"; do
      printf -- '- %s\n' "$suggestion"
    done
    echo ""
  fi
}

main() {
  parse_args "$@"

  source "$SCRIPT_DIR/checks/core.sh"
  source "$SCRIPT_DIR/checks/system.sh"
  source "$SCRIPT_DIR/checks/editor.sh"

  print_header "System Health Check"
  run_checks
  print_summary

  if [[ $ERRORS -gt 0 ]]; then
    exit 2
  elif [[ $WARNINGS -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
