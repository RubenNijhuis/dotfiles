#!/usr/bin/env bash
# Shared utility helpers for dotfiles scripts.

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
    echo "Missing required command: $cmd"
    echo "$hint"
    return 1
  fi
}

validate_profile() {
  local profile="$1"
  case "$profile" in
    personal|work) return 0 ;;
    *)
      echo "Invalid profile: '$profile' (expected 'personal' or 'work')" >&2
      return 1
      ;;
  esac
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
