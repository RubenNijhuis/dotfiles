#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] <profile-name>

Set the active machine profile in local/profile.env.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      -*)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
      *)
        ARGS+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#ARGS[@]} -ne 1 ]]; then
    usage
    exit 1
  fi
}

main() {
  parse_args "$@"

  local profile_name="${ARGS[0]}"
  local profile_file="$DOTFILES/profiles/${profile_name}.env"
  local target_file="$DOTFILES/local/profile.env"

  if [[ ! -f "$profile_file" ]]; then
    print_error "Unknown profile: $profile_name"
    print_info "Run: make profile-list"
    exit 1
  fi

  mkdir -p "$(dirname "$target_file")"
  printf 'DOTFILES_PROFILE="%s"\n' "$profile_name" > "$target_file"
  print_success "Active profile set to $profile_name"
  print_dim "  Stored in local/profile.env"
}

main "$@"
