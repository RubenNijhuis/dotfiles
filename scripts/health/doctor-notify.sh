#!/usr/bin/env bash
# Run doctor.sh and send notification if issues found
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

DOCTOR_ARGS=(--quick --no-color)

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--full]

Run doctor checks and show a macOS notification when issues are found.
Defaults to quick mode; use --full for full checks.
EOF2
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

  local log_dir="$HOME/.local/log"
  mkdir -p "$log_dir"

  set +e
  local output
  output=$(bash "$DOTFILES/scripts/health/doctor.sh" "${DOCTOR_ARGS[@]}" 2>&1)
  local exit_code=$?
  set -e

  echo "$(date '+%Y-%m-%d %H:%M:%S'): Health check completed (exit code: $exit_code)" >> "$log_dir/dotfiles-doctor-summary.log"
  echo "$output" >> "$log_dir/dotfiles-doctor.out.log"

  if [[ $exit_code -ne 0 ]]; then
    osascript -e 'display notification "Run make doctor for details" with title "Dotfiles Health Check Failed"' 2>/dev/null || true
    exit "$exit_code"
  fi
}

main "$@"
