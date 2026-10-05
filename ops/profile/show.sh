#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/cli.sh"
source "$SCRIPT_DIR/../../lib/env.sh"
source "$SCRIPT_DIR/../../lib/brew.sh"
dotfiles_load_env "$DOTFILES"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Show the active machine profile, its Brewfile selection, and launchd
automations. Nix host imports select capability profiles and Home Manager
owns declarative configuration; private overrides stay user-owned.
EOF
}

main() {
  parse_standard_args usage "$@"

  print_header "Active Profile"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
  print_status_row "Label" info "${DOTFILES_PROFILE_LABEL:-${DOTFILES_PROFILE:-unknown}}"
  print_status_row "Brewfiles" info "$(brew_profile_summary)"
  print_status_row "Automations" info "$(printf '%s' "${DOTFILES_PROFILE_AUTOMATIONS:-}" | wc -w | xargs) selected"
  print_dim "  ${DOTFILES_PROFILE_AUTOMATIONS:-none}"
  print_status_row "Configuration" info "Nix / Home Manager; user-owned private overrides"
}

main "$@"
