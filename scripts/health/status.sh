#!/usr/bin/env bash
# Unified system status — actionable overview of dotfiles health.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/env.sh"
dotfiles_load_env "$DOTFILES"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Unified system status check. Shows only actionable items.

Options:
  --no-color    Disable colored output
  --help, -h    Show this help message
EOF
}

parse_args() {
  show_help_if_requested usage "$@"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color) shift ;;
      *) print_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done
}

ISSUES=0

check_doctor() {
  local output exit_code=0
  output=$(bash "$DOTFILES/scripts/health/doctor.sh" --quick --no-color 2>&1) || exit_code=$?

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
    ISSUES=$((ISSUES + 1))
  fi
}

check_stow() {
  local stow_dir="$DOTFILES/stow"
  local total=0 broken=0

  # Count packages
  total=$(find "$stow_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | xargs)

  # Check for broken symlinks in home directory
  while IFS= read -r link; do
    if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
      broken=$((broken + 1))
    fi
  done < <(find "$HOME" -maxdepth 1 -type l 2>/dev/null)

  if [[ $broken -eq 0 ]]; then
    print_success "Stow: $total packages, no broken symlinks"
  else
    print_error "Stow: $broken broken symlinks"
    print_dim "  → Run: make unstow && make stow"
    ISSUES=$((ISSUES + 1))
  fi
}

check_launchd() {
  source "$DOTFILES/scripts/automation/launchd/common.sh"
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
    local missing=$((managed - loaded))
    print_warning "LaunchD: $loaded/$managed agents loaded"
    print_dim "  → $missing not loaded. Run: make automation-setup"
    ISSUES=$((ISSUES + 1))
  else
    print_warning "LaunchD: no agents loaded"
    print_dim "  → Run: make automation-setup"
    ISSUES=$((ISSUES + 1))
  fi
}

check_backup() {
  local backup_dir="$HOME/.dotfiles-backup"
  if [[ ! -d "$backup_dir" ]]; then
    print_warning "Backup: no backups found"
    print_dim "  → Run: make backup"
    ISSUES=$((ISSUES + 1))
    return
  fi

  local latest
  latest=$(find "$backup_dir" -maxdepth 1 -type d -name "202*" | sort -r | head -n1)
  if [[ -z "$latest" ]]; then
    print_warning "Backup: no backups found"
    print_dim "  → Run: make backup"
    ISSUES=$((ISSUES + 1))
    return
  fi

  local age_days
  age_days=$(( ($(date +%s) - $(stat -f %m "$latest")) / 86400 ))
  if [[ $age_days -le 7 ]]; then
    print_success "Backup: ${age_days}d ago"
  else
    print_warning "Backup: ${age_days}d ago (stale)"
    print_dim "  → Run: make backup"
    ISSUES=$((ISSUES + 1))
  fi
}

check_docs() {
  if bash "$DOTFILES/scripts/docs/generate-cli-reference.sh" --check --no-color >/dev/null 2>&1; then
    print_success "Docs: up to date"
  else
    print_warning "Docs: generated reference is stale"
    print_dim "  → Run: make docs-sync"
    ISSUES=$((ISSUES + 1))
  fi
}

main() {
  parse_args "$@"

  print_header "System Status"

  check_doctor
  check_stow
  check_launchd
  check_backup
  check_docs

  echo ""
  if [[ $ISSUES -eq 0 ]]; then
    print_success "All clear"
  else
    print_dim "$ISSUES item(s) need attention"
  fi
}

main "$@"
