#!/usr/bin/env bash
# Generate SSH keys for personal and work profiles

set -euo pipefail

PROFILE_FILE="$HOME/.config/dotfiles-profile"

if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "Error: Profile not set. Run install.sh first."
    exit 1
fi

PROFILE="$(cat "$PROFILE_FILE")"

echo "Current profile: $PROFILE"
echo ""

# Read email from git config
PERSONAL_EMAIL=$(git config --file ~/.gitconfig-personal user.email 2>/dev/null || echo "")
WORK_EMAIL=$(git config --file ~/.gitconfig-work user.email 2>/dev/null || echo "")

# Generate personal key
if [[ ! -f ~/.ssh/id_ed25519_personal ]]; then
    echo "Generating personal SSH key..."
    read -rp "Personal email [$PERSONAL_EMAIL]: " email
    email="${email:-$PERSONAL_EMAIL}"
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519_personal
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal
    echo "✓ Personal key generated"
else
    echo "✓ Personal key already exists"
fi

# Generate work key (only if work profile)
if [[ "$PROFILE" == "work" ]]; then
    if [[ ! -f ~/.ssh/id_ed25519_work ]]; then
        echo ""
        echo "Generating work SSH key..."
        read -rp "Work email [$WORK_EMAIL]: " email
        email="${email:-$WORK_EMAIL}"
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519_work
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519_work
        echo "✓ Work key generated"
    else
        echo "✓ Work key already exists"
    fi
fi

echo ""
echo "SSH keys generated successfully!"
echo ""
echo "Next steps:"
echo "  1. Add your public keys to GitHub/GitLab:"
echo "     - Personal: pbcopy < ~/.ssh/id_ed25519_personal.pub"
if [[ "$PROFILE" == "work" ]]; then
    echo "     - Work: pbcopy < ~/.ssh/id_ed25519_work.pub"
fi
echo "  2. Test connection: ssh -T git@github.com"
