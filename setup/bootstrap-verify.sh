#!/usr/bin/env bash
# Verify fresh-machine bootstrap contracts without mutating host config.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

RUN_DOCTOR=true

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--skip-doctor]

Runs bootstrap verification:
  1. install.sh dry-run
  2. script CLI tests
  3. docs sync check
  4. quick doctor check
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --skip-doctor)
        RUN_DOCTOR=false
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

run_step() {
  local title="$1"
  shift

  print_section "$title"
  if "$@"; then
    print_success "$title"
  else
    print_error "$title failed"
    return 1
  fi
}

main() {
  parse_args "$@"

  print_header "Bootstrap Verification"

  run_step "Installer dry-run" \
    bash "$DOTFILES/install.sh" --dry-run --yes --without-macos-defaults --without-ssh --without-gpg

  run_step "CLI parsing checks" bash "$DOTFILES/tests/test-cli-parsing.sh"
  run_step "CLI contract checks" bash "$DOTFILES/tests/test-cli-contract.sh"
  run_step "Install checkpoint checks" bash "$DOTFILES/tests/test-install-checkpoint.sh"
  run_step "Keychain requirement checks" bash "$DOTFILES/setup/check-keychain.sh" --no-color
  run_step "Docs sync check" bash "$DOTFILES/ops/generate-cli-reference.sh" --check

  if $RUN_DOCTOR; then
    run_step "Doctor quick check" bash "$DOTFILES/health/doctor.sh" --quick --no-color
  else
    print_warning "Skipping doctor check (--skip-doctor)"
  fi

  print_success "Bootstrap verification complete"
}

main "$@"
