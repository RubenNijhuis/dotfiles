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

Show the active machine profile, its Brewfile selection, and launchd
automations. Config files themselves are now managed by chezmoi —
run 'chezmoi managed' to inspect that side.
EOF
}

main() {
  parse_standard_args usage "$@"

  print_header "Active Profile"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
  print_status_row "Label" info "${DOTFILES_PROFILE_LABEL:-${DOTFILES_PROFILE:-unknown}}"
  print_status_row "Brewfiles" info "${DOTFILES_PROFILE_BREWFILES:-Brewfile.cli Brewfile.apps Brewfile.vscode}"
  print_status_row "Automations" info "$(printf '%s' "${DOTFILES_PROFILE_AUTOMATIONS:-dotfiles-backup dotfiles-doctor repo-update log-cleanup brew-audit weekly-digest}" | wc -w | xargs) selected"
  print_dim "  ${DOTFILES_PROFILE_AUTOMATIONS:-dotfiles-backup dotfiles-doctor repo-update log-cleanup brew-audit weekly-digest}"
  if command -v chezmoi >/dev/null 2>&1; then
    local managed
    managed=$(chezmoi managed --include=files 2>/dev/null | wc -l | xargs)
    print_status_row "chezmoi files" info "$managed managed"
  fi
}

main "$@"
