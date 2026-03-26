#!/usr/bin/env bash
# Display SSH key information and status
set -euo pipefail

# Load output utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Display SSH key, agent, and config status.
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

print_header "SSH Public Keys"

found_keys=false
for key in ~/.ssh/*.pub; do
    if [[ -f "$key" ]]; then
        found_keys=true
        printf -- "\n"
        print_subsection "$(basename "$key")"
        ssh-keygen -lf "$key" 2>/dev/null | while IFS= read -r line; do
            print_indent "$line"
        done
    fi
done

if ! $found_keys; then
    print_warning "No public keys found in ~/.ssh/"
fi

printf -- "\n"
print_header "Keys in SSH Agent"

if ssh-add -l &>/dev/null; then
    ssh-add -l | while IFS= read -r line; do
        print_success "$line"
    done
else
    print_warning "No keys loaded in agent"
    print_dim "    Load keys with: ssh-add ~/.ssh/id_ed25519_personal"
fi

printf -- "\n"
print_header "SSH Configuration"

if [[ -f ~/.ssh/config ]]; then
    print_success "Config file exists: ~/.ssh/config"

    # Check for includes
    if grep -q "^Include" ~/.ssh/config 2>/dev/null; then
        include_count=$(find ~/.ssh/config.d -name "*.conf" 2>/dev/null | wc -l | xargs)
        print_bullet "Include directive found ($include_count config files)"
    fi

    # Show key configuration patterns
    if grep -q "IdentityFile" ~/.ssh/config 2>/dev/null; then
        print_bullet "Custom identity files configured"
    fi
else
    print_error "Config file not found: ~/.ssh/config"
    print_dim "    Create with: make stow"
fi

printf -- "\n"
print_info "Test SSH config with: ssh -G github.com"
print_info "Generate new keys with: make ssh-setup"
