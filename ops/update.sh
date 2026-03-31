#!/usr/bin/env bash
# Update repos, brew packages, runtimes, global packages, and re-stow configs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Update repos, Homebrew packages, runtime tools, global packages, and restow configs.
EOF
}

update_repos() {
  local output
  if output=$(bash "$DOTFILES/ops/update-repos.sh" --quiet ${NO_COLOR:+--no-color} 2>&1); then
    print_step "Repositories" success "$output"
    return 0
  fi
  print_step "Repositories" error "$output"
  return 1
}

update_homebrew() {
  if ! command -v brew &>/dev/null; then
    print_step "Homebrew" warning "not found"
    return 1
  fi

  brew autoremove &>/dev/null || true

  if brew update &>/dev/null && brew upgrade &>/dev/null && brew cleanup &>/dev/null; then
    print_step "Homebrew" success "updated"
    return 0
  fi

  print_step "Homebrew" error "update failed"
  return 1
}

update_runtimes() {
  if ! command -v mise &>/dev/null; then
    print_step "Runtimes (mise)" skip "not installed"
    return 0
  fi

  if mise upgrade &>/dev/null; then
    print_step "Runtimes (mise)" success "updated"
  else
    print_step "Runtimes (mise)" warning "upgrade failed"
  fi
}

update_global_packages() {
  if ! command -v pnpm &>/dev/null; then
    print_step "Global packages" skip "pnpm not installed"
    return 0
  fi

  if pnpm update -g &>/dev/null; then
    print_step "Global packages" success "updated"
  else
    print_step "Global packages" warning "update failed"
  fi
}

restow_configs() {
  local output
  if output=$(bash "$DOTFILES/setup/stow-all.sh" --quiet ${NO_COLOR:+--no-color} 2>&1); then
    print_step "Stow configs" success "$output"
    return 0
  fi
  print_step "Stow configs" error "failed"
  return 1
}

main() {
  parse_standard_args usage "$@"
  print_header "System Update"

  local failures=0

  update_repos           || failures=$((failures + 1))
  update_homebrew        || failures=$((failures + 1))
  update_runtimes        || failures=$((failures + 1))
  update_global_packages || failures=$((failures + 1))
  restow_configs         || failures=$((failures + 1))

  printf '\n'
  if [[ $failures -gt 0 ]]; then
    print_warning "$failures step(s) had issues — run 'make doctor' to check"
    exit 1
  fi

  print_success "All up to date"
}

main "$@"
