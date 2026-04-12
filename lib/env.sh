#!/usr/bin/env bash
# Shared environment defaults for dotfiles scripts.

dotfiles_profile_file() {
  local dotfiles_root="${1:-${DOTFILES:-}}"
  printf '%s\n' "$dotfiles_root/local/profile.env"
}

dotfiles_profile_path() {
  local dotfiles_root="$1"
  local profile_name="$2"
  printf '%s\n' "$dotfiles_root/profiles/${profile_name}.env"
}

dotfiles_load_profile() {
  local dotfiles_root="$1"
  local selected_profile="${DOTFILES_PROFILE:-}"
  local local_profile_file
  local profile_path

  local_profile_file="$(dotfiles_profile_file "$dotfiles_root")"
  if [[ -f "$local_profile_file" ]]; then
    # shellcheck disable=SC1090
    source "$local_profile_file"
    selected_profile="${DOTFILES_PROFILE:-$selected_profile}"
  fi

  selected_profile="${selected_profile:-personal-laptop}"
  profile_path="$(dotfiles_profile_path "$dotfiles_root" "$selected_profile")"

  if [[ ! -f "$profile_path" ]]; then
    echo "Missing profile definition: $profile_path" >&2
    return 1
  fi

  export DOTFILES_PROFILE="$selected_profile"
  export DOTFILES_PROFILE_PATH="$profile_path"
  # shellcheck disable=SC1090
  source "$profile_path"
}

dotfiles_profile_packages() {
  local packages="${DOTFILES_PROFILE_STOW_PACKAGES:-}"
  if [[ -z "$packages" || "$packages" == "*" ]]; then
    return 0
  fi

  local pkg
  for pkg in $packages; do
    printf '%s\n' "$pkg"
  done
}

dotfiles_load_env() {
  local dotfiles_root="${1:-${DOTFILES:-}}"

  if [[ -z "$dotfiles_root" ]]; then
    dotfiles_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  fi

  # Optional machine-local overrides.
  if [[ -f "$dotfiles_root/local/machine.env" ]]; then
    # shellcheck disable=SC1090
    source "$dotfiles_root/local/machine.env"
  fi

  dotfiles_load_profile "$dotfiles_root"

  if [[ -z "${DOTFILES_HOMEBREW_PREFIX:-}" ]]; then
    if command -v brew >/dev/null 2>&1; then
      DOTFILES_HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
    fi
    DOTFILES_HOMEBREW_PREFIX="${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}"
  fi

  export DOTFILES_DEVELOPER_ROOT="${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"
  if [[ ! -d "$DOTFILES_DEVELOPER_ROOT" && -z "${DOTFILES_SKIP_DIR_CHECK:-}" ]]; then
    mkdir -p "$DOTFILES_DEVELOPER_ROOT"
  fi
  export DOTFILES_LMSTUDIO_HOME="${DOTFILES_LMSTUDIO_HOME:-$HOME/.lmstudio}"
  export DOTFILES_EDITOR="${DOTFILES_EDITOR:-nvim}"
  export DOTFILES_HOMEBREW_PREFIX
  export DOTFILES_OBSIDIAN_REPO_PATH="${DOTFILES_OBSIDIAN_REPO_PATH:-$DOTFILES_DEVELOPER_ROOT/personal/projects/obsidian-store}"
  export DOTFILES_SCREENSHOTS_PATH="${DOTFILES_SCREENSHOTS_PATH:-$HOME/Desktop/Screenshots}"
}
