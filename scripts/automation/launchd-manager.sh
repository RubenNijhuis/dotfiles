#!/usr/bin/env bash
# Unified LaunchD agent management tool
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034  # Used by sourced launchd module files.
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/launchd/common.sh"
source "$SCRIPT_DIR/launchd/commands.sh"

parse_args() {
  show_help_if_requested show_usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
  fi

  COMMAND="$1"
  AGENT="${2:-}"
}

main() {
  local command=""
  local agent=""

  parse_args "$@"
  command="$COMMAND"
  agent="$AGENT"
  run_command "$command" "$agent"
}

main "$@"
