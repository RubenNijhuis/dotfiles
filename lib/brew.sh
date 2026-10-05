#!/usr/bin/env bash
# Shared Homebrew/Brewfile helpers.

brewfile_paths() {
  local dotfiles_root="${1:-${DOTFILES:-}}"
  local selection="${DOTFILES_PROFILE_BREWFILES:-}"
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

  if [[ "$line" =~ ^(brew|cask|tap|mas)[[:space:]]+\"([^\"]+)\" ]]; then
    kind="${BASH_REMATCH[1]}"
    name="${BASH_REMATCH[2]}"
    normalized="$(brew_normalize_entry_name "$kind" "$name")"
    printf '%s:%s\n' "$kind" "$normalized"
    return 0
  fi

  return 1
}

brew_profile_summary() {
  local selection="${DOTFILES_PROFILE_BREWFILES:-}"
  if [[ -z "$selection" ]]; then
    printf '%s\n' "none (Nix-only)"
    return
  fi
  printf '%s\n' "$selection"
}

brew_declared_taps() {
  local brewfile
  while IFS= read -r brewfile; do
    [[ -f "$brewfile" ]] || { printf 'Missing Brewfile: %s\n' "$brewfile" >&2; return 1; }
    awk -F'"' '/^tap "/{print $2}' "$brewfile"
  done < <(brewfile_paths "${1:-${DOTFILES:-}}")
}

brew_trust_declared_taps() {
  # Installed leftovers do not grant permission to trust third-party code.
  local taps tap
  taps="$(brew_declared_taps "${1:-${DOTFILES:-}}")" || return 1
  while IFS= read -r tap; do
    [[ -n "$tap" ]] || continue
    brew trust --tap "$tap" || return 1
  done < <(printf '%s\n' "$taps" | sort -u)
}

export -f brewfile_paths brew_normalize_entry_name brew_entry_key_from_line brew_profile_summary \
  brew_declared_taps brew_trust_declared_taps
