#!/usr/bin/env bash
# Run doctor.sh and send notification if issues found
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

DOCTOR_ARGS=(--quick --no-color)

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--full]

Run doctor checks and show a macOS notification when issues are found.
Defaults to quick mode; use --full for full checks.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full)
        DOCTOR_ARGS=(--no-color)
        shift
        ;;
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

  run_automation \
    "doctor-notify" \
    "$DOTFILES/scripts/health/doctor.sh" \
    "$HOME/.local/log/dotfiles-doctor.out.log" \
    "Health Check" \
    -- "${DOCTOR_ARGS[@]}"
}

main "$@"
