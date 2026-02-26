#!/usr/bin/env bash
# Unstow all config packages
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
STOW_DIR="$DOTFILES/stow"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Unstow all packages from stow/ out of \$HOME.
EOF
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

unstow_packages() {
  local unstowed_count=0
  local failed_count=0
  local pkg_dir pkg stow_output filtered_output

  for pkg_dir in "$STOW_DIR"/*/; do
    pkg="$(basename "$pkg_dir")"

    if stow_output=$(stow -d "$STOW_DIR" -t "$HOME" -D "$pkg" 2>&1); then
      print_success "$pkg"
      unstowed_count=$((unstowed_count + 1))
      filtered_output=$(printf '%s\n' "$stow_output" | grep -v "BUG in find_stowed_path" || true)
      if [[ -n "$filtered_output" ]]; then
        print_dim "    $filtered_output"
      fi
    else
      print_error "$pkg failed"
      filtered_output=$(printf '%s\n' "$stow_output" | grep -v "BUG in find_stowed_path" || true)
      if [[ -n "$filtered_output" ]]; then
        print_dim "    $filtered_output"
      fi
      failed_count=$((failed_count + 1))
    fi
  done

  printf '\n'
  if [[ $failed_count -eq 0 ]]; then
    print_header "Unstow Complete"
    print_success "Successfully unstowed $unstowed_count packages"
    return 0
  fi

  print_error "Failed to unstow $failed_count packages"
  return 1
}

main() {
  parse_args "$@"
  require_cmd "stow" "Install stow: brew install stow" >/dev/null || {
    print_error "GNU Stow is required"
    exit 1
  }
  print_header "Unstowing Configuration Packages"
  unstow_packages
}

main "$@"
