#!/usr/bin/env bash
# Shared Homebrew/Brewfile helpers.

brewfile_paths() {
  local dotfiles_root="${1:-${DOTFILES:-}}"
  local selection="${DOTFILES_PROFILE_BREWFILES:-Brewfile.cli Brewfile.apps Brewfile.vscode}"
  local name

  for name in $selection; do
    printf '%s/brew/%s\n' "$dotfiles_root" "$name"
  done
}

brew_normalize_entry_name() {
  local kind="$1"
  local name="$2"

  case "$kind" in
    # Homebrew strips 'homebrew-' prefix from tap repos on install:
    # user/homebrew-repo → user/repo
    tap) printf '%s\n' "${name/\/homebrew-/\/}" ;;
    *) printf '%s\n' "${name##*/}" ;;
  esac
}

brew_entry_key_from_line() {
  local line="$1"
  local kind name normalized

  if [[ "$line" =~ ^(brew|cask|tap|vscode|mas)[[:space:]]+\"([^\"]+)\" ]]; then
    kind="${BASH_REMATCH[1]}"
    name="${BASH_REMATCH[2]}"
    normalized="$(brew_normalize_entry_name "$kind" "$name")"
    printf '%s:%s\n' "$kind" "$normalized"
    return 0
  fi

  return 1
}

brew_profile_summary() {
  local selection="${DOTFILES_PROFILE_BREWFILES:-Brewfile.cli Brewfile.apps Brewfile.vscode}"
  printf '%s\n' "$selection"
}

export -f brewfile_paths brew_normalize_entry_name brew_entry_key_from_line brew_profile_summary
