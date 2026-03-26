#!/usr/bin/env bash
# Generate SSH keys for personal and (optionally) work identities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Generate SSH keys for personal and (optionally) work identities.
EOF
}

show_help_if_requested usage "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color) shift ;;
    *) print_error "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

print_header "SSH Key Generation"
printf '\n'

# Ensure ~/.ssh exists with secure permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Read email from git config
PERSONAL_EMAIL=$(git config --file ~/.gitconfig-personal user.email 2>/dev/null || echo "")
WORK_EMAIL=$(git config --file ~/.gitconfig-work user.email 2>/dev/null || echo "")

# Generate personal key
if [[ ! -f ~/.ssh/id_ed25519_personal ]]; then
    print_info "Generating personal SSH key..."
    read -rp "Personal email [$PERSONAL_EMAIL]: " email
    email="${email:-$PERSONAL_EMAIL}"
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519_personal
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal
    print_success "Personal key generated"
else
    print_success "Personal key already exists"
fi

# Optionally generate work key
if [[ ! -f ~/.ssh/id_ed25519_work ]]; then
    printf '\n'
    if confirm "Generate a work SSH key? [y/N] "; then
        print_info "Generating work SSH key..."
        read -rp "Work email [$WORK_EMAIL]: " email
        email="${email:-$WORK_EMAIL}"
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519_work
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519_work
        print_success "Work key generated"
    fi
else
    print_success "Work key already exists"
fi

printf '\n'
print_success "SSH keys generated successfully!"
printf '\n'
print_section "Next steps"
print_indent "1. Add your public keys to GitHub/GitLab:"
print_indent "   Personal: pbcopy < ~/.ssh/id_ed25519_personal.pub"
if [[ -f ~/.ssh/id_ed25519_work ]]; then
    print_indent "   Work: pbcopy < ~/.ssh/id_ed25519_work.pub"
fi
print_indent "2. Test connection: ssh -T git@github.com"
