#!/usr/bin/env bash
# Stow all config packages from config/ into ~
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
STOW_DIR="$DOTFILES/config"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Stow all packages from config/ into \$HOME.
EOF
}

backup_before_stow() {
  print_section "Creating backup..."
  if [[ -f "$DOTFILES/ops/backup-dotfiles.sh" ]]; then
    if bash "$DOTFILES/ops/backup-dotfiles.sh" &>/dev/null; then
      print_success "Backup created"
    else
      print_warning "Backup failed, but continuing"
    fi
  else
    print_dim "    No backup script found, skipping"
  fi
}

cleanup_old_symlinks() {
  printf '\n'
  print_section "Cleaning up old symlinks..."

  local old_symlinks=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.zshenv"
    "$HOME/.gitconfig"
    "$HOME/.gitconfig-personal"
    "$HOME/.gitconfig-work"
    "$HOME/.gitignore_global"
  )

  local removed_count=0
  local link target
  for link in "${old_symlinks[@]}"; do
    if [[ -L "$link" ]]; then
      target="$(readlink "$link")"
      # Only remove if it points into dotfiles/ (old manual setup)
      if [[ "$target" == *dotfiles/* && "$target" != *dotfiles/config/* ]]; then
        print_dim "    Removing old symlink: $(basename "$link")"
        rm "$link"
        removed_count=$((removed_count + 1))
      fi
    fi
  done

  if [[ $removed_count -gt 0 ]]; then
    print_success "Removed $removed_count old symlinks"
  else
    print_dim "    No old symlinks found"
  fi
}

stow_packages() {
  printf '\n'
  print_section "Stowing packages..."

  local stowed_count=0
  local failed_count=0
  local skipped_count=0
  local pkg_dir pkg stow_output filtered_output
  local -a succeeded_pkgs=()
  local -a failed_pkgs=()

  for pkg_dir in "$STOW_DIR"/*/; do
    pkg="$(basename "$pkg_dir")"

    if stow_output=$(stow -d "$STOW_DIR" -t "$HOME" "$pkg" 2>&1); then
      print_success "$pkg"
      stowed_count=$((stowed_count + 1))
      succeeded_pkgs+=("$pkg")
      # GNU Stow emits a spurious "BUG in find_stowed_path" warning when
      # target directories already exist (known upstream issue). Filter it
      # to avoid confusing output.
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
      print_dim "    Run 'make stow-report' to see conflicts, or 'make unstow' first"
      failed_count=$((failed_count + 1))
      failed_pkgs+=("$pkg")
    fi
  done

  printf '\n'
  if [[ $skipped_count -gt 0 ]]; then
    print_warning "Skipped $skipped_count package(s) with expected local conflicts"
  fi

  if [[ $failed_count -eq 0 ]]; then
    print_header "Stow Complete"
    if [[ $skipped_count -gt 0 ]]; then
      print_success "Successfully stowed $stowed_count packages ($skipped_count skipped)"
    else
      print_success "Successfully stowed $stowed_count packages"
    fi
    print_dim "  Next: run 'make doctor' to verify system health"
    return 0
  fi

  print_error "Failed to stow $failed_count package(s): ${failed_pkgs[*]}"
  if [[ $stowed_count -gt 0 ]]; then
    print_info "Successfully stowed: ${succeeded_pkgs[*]}"
  fi
  return 1
}

main() {
  parse_standard_args usage "$@"
  require_cmd "stow" "Install stow: brew install stow" || exit 1
  print_header "Stowing Configuration Packages"

  backup_before_stow
  cleanup_old_symlinks
  stow_packages
}

main "$@"
