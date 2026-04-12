#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/cli.sh"
source "$SCRIPT_DIR/../../lib/env.sh"
dotfiles_load_env "$DOTFILES"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

List available machine profiles.
EOF
}

parse_standard_args usage "$@"

print_header "Available Profiles"

while IFS= read -r profile_file; do
  profile_name="$(basename "$profile_file" .env)"
  printf "  "
  if [[ "$profile_name" == "${DOTFILES_PROFILE:-}" ]]; then
    print_success "$profile_name (active)"
  else
    print_info "$profile_name"
  fi
done < <(find "$DOTFILES/profiles" -maxdepth 1 -type f -name '*.env' | sort)
