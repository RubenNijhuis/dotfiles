#!/usr/bin/env bash
# Validate required macOS Keychain entries for dotfiles automation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

CONFIG_FILE="$DOTFILES/local/keychain-required.txt"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--config <path>]

Validate required keychain items listed one service name per line.
Default config: local/keychain-required.txt
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --config)
        if [[ $# -lt 2 ]]; then
          print_error "Missing value for --config"
          usage
          exit 1
        fi
        CONFIG_FILE="$2"
        shift 2
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

  if ! command -v security >/dev/null 2>&1; then
    print_error "macOS security command not found"
    exit 1
  fi

  if [[ ! -f "$CONFIG_FILE" ]]; then
    print_warning "No required keychain config file found at $CONFIG_FILE"
    print_info "Create it from templates/local/keychain-required.txt.example if needed"
    exit 0
  fi

  print_header "Keychain Requirement Check"

  local missing=0
  while IFS= read -r service; do
    service="${service%%#*}"
    service="$(echo "$service" | xargs)"
    [[ -z "$service" ]] && continue

    if security find-generic-password -s "$service" >/dev/null 2>&1; then
      print_success "$service"
    else
      print_error "$service (missing)"
      missing=$((missing + 1))
    fi
  done < "$CONFIG_FILE"

  if [[ "$missing" -gt 0 ]]; then
    print_error "Missing $missing required keychain item(s)"
    exit 1
  fi

  print_success "All required keychain items are present"
}

main "$@"
