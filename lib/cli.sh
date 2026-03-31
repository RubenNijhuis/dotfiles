#!/usr/bin/env bash
# Shared CLI argument parsing for scripts with standard flags.

# Parse standard CLI arguments (--help, --no-color, --dry-run).
# Sets DRY_RUN=true when --dry-run is passed (caller must declare DRY_RUN=false beforehand).
#
# Usage:
#   parse_standard_args usage "$@"                   # --help + --no-color only
#   parse_standard_args usage --accept-dry-run "$@"  # also accept --dry-run
parse_standard_args() {
  local usage_fn="$1"; shift

  local accept_dry_run=false
  if [[ "${1:-}" == "--accept-dry-run" ]]; then
    accept_dry_run=true
    shift
  fi

  show_help_if_requested "$usage_fn" "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color|--quiet)
        shift
        ;;
      --dry-run)
        if $accept_dry_run; then
          # shellcheck disable=SC2034
          DRY_RUN=true
          shift
        else
          print_error "Unknown argument: $1"
          "$usage_fn"
          exit 1
        fi
        ;;
      *)
        print_error "Unknown argument: $1"
        "$usage_fn"
        exit 1
        ;;
    esac
  done
}
