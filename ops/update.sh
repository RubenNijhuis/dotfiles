#!/usr/bin/env bash
# Update brew packages and re-stow configs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Update Homebrew packages, runtime tools, and restow configs.
EOF
}

update_homebrew() {
  print_section "Updating Homebrew packages..."
  if ! require_cmd "brew" "Install Homebrew first: https://brew.sh"; then
    print_error "Homebrew not found"
    return 1
  fi

  # Remove orphaned dependencies first to avoid noisy "Skipping/Autoremoving" warnings
  brew autoremove &>/dev/null || true

  if brew update && brew upgrade && brew cleanup; then
    print_success "Homebrew packages updated"
    return 0
  fi

  print_error "Homebrew update failed"
  return 1
}

update_node_lts() {
  printf '\n'
  print_section "Updating Node.js (fnm)..."

  if ! command -v fnm &>/dev/null; then
    print_warning "fnm not found, skipping Node update"
    print_dim "    Install with: brew install fnm"
    return 0
  fi

  local current_version new_version
  current_version=$(node --version 2>/dev/null || echo "none")
  print_dim "    Current version: $current_version"

  if fnm install --lts &>/dev/null; then
    new_version=$(node --version)
    if [[ "$new_version" != "$current_version" ]]; then
      print_success "Updated to $new_version"
    else
      print_success "Already on latest LTS: $new_version"
    fi
  else
    print_warning "Failed to update Node.js"
  fi
}

update_global_packages() {
  printf '\n'
  print_section "Updating global packages..."

  if ! command -v pnpm &>/dev/null; then
    print_warning "pnpm not found, skipping global package update"
    print_dim "    Install with: brew install pnpm"
    return 0
  fi

  if pnpm update -g &>/dev/null; then
    print_success "Global packages updated"
  else
    print_warning "Failed to update global packages"
  fi
}

restow_configs() {
  printf '\n'
  print_section "Re-stowing configuration files..."

  if bash "$DOTFILES/setup/stow-all.sh"; then
    print_success "Configurations re-stowed"
    return 0
  fi

  print_error "Failed to re-stow configurations"
  return 1
}

main() {
  parse_standard_args usage "$@"
  print_header "System Update"

  local failures=0

  update_homebrew  || failures=$((failures + 1))
  update_node_lts  || failures=$((failures + 1))
  update_global_packages || failures=$((failures + 1))
  restow_configs   || failures=$((failures + 1))

  printf '\n'
  if [[ $failures -gt 0 ]]; then
    print_warning "Update finished with $failures failed step(s)"
    print_info "Run 'make doctor' to diagnose issues"
    exit 1
  fi

  print_success "All updates finished successfully"
  print_info "Run 'make doctor' to verify system health"
}

main "$@"
