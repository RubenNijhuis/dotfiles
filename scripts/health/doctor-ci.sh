#!/usr/bin/env bash
# Deterministic CI health gate for this macOS-only repository.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

PROFILE="personal"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--profile <personal|work>]

Run deterministic CI health checks:
  1. check-scripts
  2. test-scripts
  3. launchd-check
  4. docs-sync
  5. install.sh dry-run
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --profile)
        if [[ $# -lt 2 ]]; then
          print_error "Missing value for --profile"
          usage
          exit 1
        fi
        PROFILE="$2"
        shift 2
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ "$PROFILE" != "personal" && "$PROFILE" != "work" ]]; then
    print_error "--profile must be personal or work"
    exit 1
  fi
}

run_step() {
  local label="$1"
  shift

  print_section "$label"
  if "$@"; then
    print_success "$label"
  else
    print_error "$label failed"
    exit 1
  fi
}

main() {
  parse_args "$@"

  print_header "CI Doctor"

  run_step "Script checks" make -s check-scripts
  run_step "Script tests" make -s test-scripts
  run_step "LaunchD contract checks" make -s launchd-check
  run_step "Docs sync" make -s docs-sync
  run_step "Installer dry-run" bash "$DOTFILES/install.sh" --dry-run --yes --profile "$PROFILE" --without-macos-defaults --without-ssh --without-gpg

  print_success "CI doctor checks passed"
}

main "$@"
