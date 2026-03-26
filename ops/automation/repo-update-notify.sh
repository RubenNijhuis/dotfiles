#!/usr/bin/env bash
# Run repository updates and send local macOS notification on completion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"

LOG_FILE="$HOME/.local/log/repo-update-summary.log"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run] [path]

Wrapper around ops/update-repos.sh with notification and summary log.
EOF
}

ARGS=()
parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --dry-run)
        ARGS+=("--dry-run")
        shift
        ;;
      *)
        if [[ "${1#-}" != "$1" ]]; then
          print_error "Unknown argument: $1"
          usage
          exit 1
        fi
        ARGS+=("$1")
        shift
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  if ! require_network; then
    print_info "Offline — skipping repository update"
    exit 0
  fi

  run_automation \
    "repo-update-notify" \
    "$DOTFILES/ops/update-repos.sh" \
    "$LOG_FILE" \
    "Repo Update" \
    --notify-on-success \
    -- --no-color "${ARGS[@]}"
}

main "$@"
