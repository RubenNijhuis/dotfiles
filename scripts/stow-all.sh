#!/usr/bin/env bash
# Stow all config packages from stow/ into ~
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
STOW_DIR="$DOTFILES/stow"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Stow all packages from stow/ into \$HOME.
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

backup_before_stow() {
  print_section "Creating backup..."
  if [[ -f "$DOTFILES/scripts/backup-dotfiles.sh" ]]; then
    if bash "$DOTFILES/scripts/backup-dotfiles.sh" &>/dev/null; then
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
    "$HOME/.p10k.zsh"
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
      if [[ "$target" == *dotfiles/* && "$target" != *dotfiles/stow/* ]]; then
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

  for pkg_dir in "$STOW_DIR"/*/; do
    pkg="$(basename "$pkg_dir")"

    if stow_output=$(stow -d "$STOW_DIR" -t "$HOME" "$pkg" 2>&1); then
      print_success "$pkg"
      stowed_count=$((stowed_count + 1))
      filtered_output=$(printf '%s\n' "$stow_output" | grep -v "BUG in find_stowed_path" || true)
      if [[ -n "$filtered_output" ]]; then
        print_dim "    $filtered_output"
      fi
    else
      # OpenClaw workspace files are often already materialized; treat as non-fatal.
      if [[ "$pkg" == "openclaw" ]] && [[ "$stow_output" == *"would cause conflicts"* ]]; then
        print_warning "$pkg skipped (existing local workspace files)"
        filtered_output=$(printf '%s\n' "$stow_output" | grep -v "BUG in find_stowed_path" || true)
        if [[ -n "$filtered_output" ]]; then
          print_dim "    $filtered_output"
        fi
        skipped_count=$((skipped_count + 1))
        continue
      fi

      print_error "$pkg failed"
      filtered_output=$(printf '%s\n' "$stow_output" | grep -v "BUG in find_stowed_path" || true)
      if [[ -n "$filtered_output" ]]; then
        print_dim "    $filtered_output"
      fi
      print_dim "    Run 'make unstow' and try again, or check for conflicts"
      failed_count=$((failed_count + 1))
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
    return 0
  fi

  print_error "Failed to stow $failed_count packages"
  return 1
}

main() {
  parse_args "$@"
  require_cmd "stow" "Install stow: brew install stow" >/dev/null || {
    print_error "GNU Stow is required"
    exit 1
  }
  print_header "Stowing Configuration Packages"

  backup_before_stow
  cleanup_old_symlinks
  stow_packages
}

main "$@"
