#!/usr/bin/env bash
# Display GPG key and configuration information
set -euo pipefail

# Load output utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Display GPG key and signing configuration status.
EOF
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

parse_args "$@"

print_header "GPG Secret Keys"

if gpg --list-secret-keys &>/dev/null 2>&1; then
    # Get key information
    while IFS= read -r line; do
        if [[ $line =~ ^sec ]]; then
            print_success "$line"
        elif [[ $line =~ ^uid ]]; then
            print_bullet "$line"
        elif [[ $line =~ ^ssb ]]; then
            print_dim "    $line"
        elif [[ -n "$line" ]]; then
            print_indent "$line"
        fi
    done < <(gpg --list-secret-keys --keyid-format=long 2>/dev/null)
else
    print_warning "No GPG secret keys found"
    print_dim "    Generate with: make gpg-setup"
fi

printf -- "\n"
print_header "Git Signing Configuration"

signing_key=$(git config --global user.signingkey 2>/dev/null || echo "")
signing=$(git config --global commit.gpgsign 2>/dev/null || echo "false")

if [[ -n "$signing_key" ]]; then
    print_key_value "Signing key" "$signing_key"
else
    print_warning "Signing key not configured"
fi

if [[ "$signing" == "true" ]]; then
    print_key_value "Auto-sign commits" "enabled"
else
    print_warning "Auto-sign commits: disabled"
fi

# Test GPG signing
printf -- "\n"
print_section "GPG Functionality Test"

if echo "test" | gpg --clear-sign &>/dev/null; then
    print_success "GPG can sign messages"
else
    print_error "GPG signing test failed"
    print_dim "    Restart GPG agent: gpgconf --kill gpg-agent && gpgconf --launch gpg-agent"
fi

printf -- "\n"
print_info "Configure GPG with: make gpg-setup"
print_info "Export public key: gpg --armor --export <key-id>"
