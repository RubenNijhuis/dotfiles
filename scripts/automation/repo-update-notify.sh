#!/usr/bin/env bash
# Run repository updates and send local macOS notification on completion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

LOG_DIR="$HOME/.local/log"
SUMMARY_LOG="$LOG_DIR/repo-update-summary.log"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--dry-run] [path]

Wrapper around scripts/maintenance/update-repos.sh with notification and summary log.
EOF2
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

send_notification() {
  local title="$1"
  local message="$2"

  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1 || true
  fi
}

main() {
  parse_args "$@"

  mkdir -p "$LOG_DIR"
  local now
  now="$(date '+%Y-%m-%d %H:%M:%S')"

  set +e
  output=$(bash "$DOTFILES/scripts/maintenance/update-repos.sh" --no-color "${ARGS[@]}" 2>&1)
  code=$?
  set -e

  {
    echo "[$now] exit=$code"
    echo "$output"
    echo ""
  } >> "$SUMMARY_LOG"

  if [[ $code -eq 0 ]]; then
    print_success "Repository update succeeded"
    send_notification "Repo Update" "Repository update completed successfully"
    exit 0
  fi

  print_error "Repository update failed"
  print_info "See $SUMMARY_LOG"
  send_notification "Repo Update" "Repository update failed - check summary log"
  exit $code
}

main "$@"
