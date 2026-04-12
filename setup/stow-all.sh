#!/usr/bin/env bash
# Stow all config packages from config/ into ~
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
STOW_DIR="$DOTFILES/config"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"
source "$SCRIPT_DIR/../lib/env.sh"
dotfiles_load_env "$DOTFILES"

QUIET=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--quiet]

Stow all packages from config/ into \$HOME.

Options:
  --quiet            Output one-line summary only
  --no-color         Disable colored output
EOF
}

# Parse --quiet before standard arg parsing
for _arg in "$@"; do
  [[ "$_arg" == "--quiet" ]] && QUIET=true
done

selected_stow_packages() {
  local -a packages=()
  local pkg_dir pkg

  if [[ -n "${DOTFILES_PROFILE_STOW_PACKAGES:-}" && "${DOTFILES_PROFILE_STOW_PACKAGES:-}" != "*" ]]; then
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      packages+=("$pkg")
    done < <(dotfiles_profile_packages)
  else
    for pkg_dir in "$STOW_DIR"/*/; do
      packages+=("$(basename "$pkg_dir")")
    done
  fi

  printf '%s\n' "${packages[@]}"
}

backup_before_stow() {
  if [[ -f "$DOTFILES/ops/backup-dotfiles.sh" ]]; then
    if bash "$DOTFILES/ops/backup-dotfiles.sh" &>/dev/null; then
      print_step "Pre-stow backup" success "created"
    else
      print_step "Pre-stow backup" warning "failed, continuing"
    fi
  fi
}

cleanup_old_symlinks() {
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
      if [[ "$target" == *dotfiles/* && "$target" != *dotfiles/config/* ]]; then
        rm "$link"
        removed_count=$((removed_count + 1))
      fi
    fi
  done

  if [[ $removed_count -gt 0 ]]; then
    print_step "Old symlinks" success "$removed_count removed"
  fi
}

stow_packages() {
  local stowed_count=0
  local failed_count=0
  local pkg stow_output filtered_output
  local -a failed_pkgs=()

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] || continue

    if stow_output=$(stow -d "$STOW_DIR" -t "$HOME" "$pkg" 2>&1); then
      stowed_count=$((stowed_count + 1))
    else
      # GNU Stow emits a spurious "BUG in find_stowed_path" warning
      filtered_output=$(printf '%s\n' "$stow_output" | grep -v "BUG in find_stowed_path" || true)
      print_step "$pkg" error "$filtered_output"
      failed_count=$((failed_count + 1))
      failed_pkgs+=("$pkg")
    fi
  done < <(selected_stow_packages)

  printf '\n'
  if [[ $failed_count -eq 0 ]]; then
    print_success "Stowed $stowed_count packages"
    return 0
  fi

  print_warning "Stowed $stowed_count packages, $failed_count failed (${failed_pkgs[*]})"
  print_dim "  Run 'make stow-report' to see conflicts, or 'make unstow' first"
  return 1
}

main() {
  parse_standard_args usage "$@"
  require_cmd "stow" "Install stow: brew install stow" || exit 1

  if $QUIET; then
    # Silent mode: just stow, output one-line summary
    local stowed=0 failed=0
    local -a failed_pkgs=()
    local pkg
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      if stow -d "$STOW_DIR" -t "$HOME" "$pkg" &>/dev/null; then
        stowed=$((stowed + 1))
      else
        failed=$((failed + 1))
        failed_pkgs+=("$pkg")
      fi
    done < <(selected_stow_packages)
    if [[ $failed -eq 0 ]]; then
      echo "$stowed packages stowed for profile ${DOTFILES_PROFILE:-unknown}"
    else
      echo "$stowed stowed, $failed failed (${failed_pkgs[*]})"
      return 1
    fi
    return 0
  fi

  print_header "Stowing Configuration Packages"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"

  backup_before_stow
  cleanup_old_symlinks
  stow_packages
}

main "$@"
