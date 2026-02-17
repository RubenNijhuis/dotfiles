#!/usr/bin/env bash
# Migrate existing SSH keys to new naming convention
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color]

Rename ~/.ssh/id_ed25519 to ~/.ssh/id_ed25519_personal.
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
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

  print_header "SSH Key Migration"

  if [[ -f ~/.ssh/id_ed25519 ]]; then
    print_info "Found existing SSH key: ~/.ssh/id_ed25519"
    print_info "This will be renamed to: ~/.ssh/id_ed25519_personal"
    echo ""

    if confirm "Proceed with migration? [y/N] " "N"; then
      mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_personal
      mv ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519_personal.pub
      print_success "Keys migrated successfully"
      echo ""
      echo "Next steps:"
      echo "  1. Update GitHub/GitLab with the same public key (no change needed)"
      echo "  2. Run: ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal"
      echo "  3. Test: ssh -T git@github.com"
    else
      print_warning "Migration cancelled"
    fi
  else
    print_warning "No existing id_ed25519 key found"
    print_info "You can generate new keys with: make ssh-setup"
  fi
}

main "$@"
