#!/usr/bin/env bash
# Validate LaunchD template contracts for managed agents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Validate launchd/*.plist against repository launchd contract.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  print_header "LaunchD Template Contract Check"

  python3 "$SCRIPT_DIR/../lib/validate_launchd.py" "$DOTFILES/launchd"

  print_success "LaunchD contracts look good"
}

main "$@"
