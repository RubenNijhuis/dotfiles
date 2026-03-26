#!/usr/bin/env bash
# Validate LaunchD template contracts for managed agents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Validate launchd/*.plist against repository launchd contract.
EOF
}

main() {
  parse_standard_args usage "$@"

  print_header "LaunchD Template Contract Check"

  python3 "$SCRIPT_DIR/../lib/validate_launchd.py" "$DOTFILES/launchd"

  print_success "LaunchD contracts look good"
}

main "$@"
