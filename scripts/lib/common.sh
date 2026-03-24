#!/usr/bin/env bash
# Shared utility helpers for dotfiles scripts.

# Valid dotfiles profiles — single source of truth.
VALID_PROFILES=(personal work)

has_flag() {
  local needle="$1"
  shift || true

  local arg
  for arg in "$@"; do
    if [[ "$arg" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

show_help_if_requested() {
  local usage_fn="$1"
  shift || true

  if has_flag "--help" "$@" || has_flag "-h" "$@"; then
    "$usage_fn"
    exit 0
  fi
}

require_cmd() {
  local cmd="$1"
  local hint="${2:-Install $cmd and retry.}"

  if ! command -v "$cmd" &>/dev/null; then
    if declare -f print_error &>/dev/null; then
      print_error "Missing required command: $cmd" >&2
      printf '  %s\n' "$hint" >&2
    else
      echo "Missing required command: $cmd" >&2
      echo "$hint" >&2
    fi
    return 1
  fi
}

validate_profile() {
  local profile="$1"
  local valid
  for valid in "${VALID_PROFILES[@]}"; do
    if [[ "$profile" == "$valid" ]]; then
      return 0
    fi
  done
  local joined
  joined="$(IFS='|'; printf '%s' "${VALID_PROFILES[*]}")"
  echo "Invalid profile: '$profile' (expected $joined)" >&2
  return 1
}

# Count broken symlinks in a directory (default: $HOME, depth 1).
# Usage: count_broken_symlinks [dir] [maxdepth]
count_broken_symlinks() {
  local dir="${1:-$HOME}"
  local maxdepth="${2:-1}"
  local count=0
  while IFS= read -r link; do
    if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
      count=$((count + 1))
    fi
  done < <(find "$dir" -maxdepth "$maxdepth" -type l 2>/dev/null)
  printf '%d' "$count"
}

confirm() {
  local prompt="$1"
  local default="${2:-N}"
  local answer

  read -rp "$prompt" answer

  if [[ -z "${answer:-}" ]]; then
    answer="$default"
  fi

  [[ "$answer" =~ ^[Yy]$ ]]
}

# Read a saved preference value from dotfiles-install-preferences.
# Returns the stored value, or the default if the file/key is absent.
get_preference() {
  local key="$1"
  local default="${2:-}"
  local prefs_file="$HOME/.config/dotfiles-install-preferences"
  if [[ -f "$prefs_file" ]]; then
    local value
    value=$(grep "^${key}=" "$prefs_file" 2>/dev/null | tail -1 | cut -d'"' -f2)
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return
    fi
  fi
  printf '%s' "$default"
}
