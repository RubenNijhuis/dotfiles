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

Show the active machine profile and its stow package selection.
EOF
}

main() {
  parse_standard_args usage "$@"

  print_header "Active Profile"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
  print_status_row "Label" info "${DOTFILES_PROFILE_LABEL:-${DOTFILES_PROFILE:-unknown}}"
  if [[ "${DOTFILES_PROFILE_STOW_PACKAGES:-*}" == "*" ]]; then
    print_status_row "Stow packages" info "all packages"
  else
    print_status_row "Stow packages" info "$(printf '%s' "${DOTFILES_PROFILE_STOW_PACKAGES}" | wc -w | xargs) selected"
    print_dim "  ${DOTFILES_PROFILE_STOW_PACKAGES}"
  fi
  print_status_row "Brewfiles" info "${DOTFILES_PROFILE_BREWFILES:-Brewfile.cli Brewfile.apps Brewfile.vscode}"
  print_status_row "Automations" info "$(printf '%s' "${DOTFILES_PROFILE_AUTOMATIONS:-dotfiles-backup dotfiles-doctor repo-update log-cleanup brew-audit weekly-digest}" | wc -w | xargs) selected"
  print_dim "  ${DOTFILES_PROFILE_AUTOMATIONS:-dotfiles-backup dotfiles-doctor repo-update log-cleanup brew-audit weekly-digest}"
}

main "$@"
