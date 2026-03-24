#!/usr/bin/env bash
# Generate SSH keys for personal and work profiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES/scripts/lib/common.sh"
source "$DOTFILES/scripts/lib/output.sh" "$@"

PROFILE_FILE="$HOME/.config/dotfiles-profile"

if [[ ! -f "$PROFILE_FILE" ]]; then
    print_error "Profile not set. Run install.sh first."
    exit 1
fi

PROFILE="$(cat "$PROFILE_FILE")"

print_header "SSH Key Generation"
print_key_value "Profile" "$PROFILE"
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

# Generate work key (only if work profile)
if [[ "$PROFILE" == "work" ]]; then
    if [[ ! -f ~/.ssh/id_ed25519_work ]]; then
        printf '\n'
        print_info "Generating work SSH key..."
        read -rp "Work email [$WORK_EMAIL]: " email
        email="${email:-$WORK_EMAIL}"
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519_work
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519_work
        print_success "Work key generated"
    else
        print_success "Work key already exists"
    fi
fi

printf '\n'
print_success "SSH keys generated successfully!"
printf '\n'
print_section "Next steps"
print_indent "1. Add your public keys to GitHub/GitLab:"
print_indent "   Personal: pbcopy < ~/.ssh/id_ed25519_personal.pub"
if [[ "$PROFILE" == "work" ]]; then
    print_indent "   Work: pbcopy < ~/.ssh/id_ed25519_work.pub"
fi
print_indent "2. Test connection: ssh -T git@github.com"
