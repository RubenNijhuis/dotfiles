#!/usr/bin/env bash
# Generate GPG key for commit signing

set -euo pipefail

PROFILE_FILE="$HOME/.config/dotfiles-profile"

if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "Error: Profile not set. Run install.sh first."
    exit 1
fi

PROFILE="$(cat "$PROFILE_FILE")"
PERSONAL_EMAIL=$(git config --file ~/.gitconfig-personal user.email 2>/dev/null || echo "")
GIT_USER=$(git config user.name 2>/dev/null || echo "")

echo "GPG Key Generation for Commit Signing"
echo "======================================"
echo ""
echo "Current profile: $PROFILE"
echo ""

# Check if GPG is installed
if ! command -v gpg &>/dev/null; then
    echo "Error: GPG is not installed. Run 'brew install gnupg pinentry-mac' first."
    exit 1
fi

# Check if pinentry-mac is installed
if [[ ! -f /opt/homebrew/bin/pinentry-mac ]]; then
    echo "Warning: pinentry-mac not found. Installing..."
    brew install pinentry-mac
fi

# Check if a GPG key already exists
EXISTING_KEYS=$(gpg --list-secret-keys --keyid-format=long "$PERSONAL_EMAIL" 2>/dev/null || echo "")

if [[ -n "$EXISTING_KEYS" ]]; then
    echo "Found existing GPG key for $PERSONAL_EMAIL:"
    echo "$EXISTING_KEYS"
    echo ""
    read -rp "Use this existing key? [Y/n] " use_existing

    if [[ "${use_existing:-Y}" =~ ^[Yy]$ ]]; then
        KEY_ID=$(echo "$EXISTING_KEYS" | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)
        echo "Using existing key: $KEY_ID"
    else
        echo "Please generate a new key manually with: gpg --full-generate-key"
        exit 0
    fi
else
    echo "Generating new GPG key..."
    echo ""
    read -rp "Name [$GIT_USER]: " name
    name="${name:-$GIT_USER}"
    read -rp "Email [$PERSONAL_EMAIL]: " email
    email="${email:-$PERSONAL_EMAIL}"

    # Generate key with batch mode
    gpg --batch --generate-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $name
Name-Email: $email
Expire-Date: 2y
%no-protection
%commit
EOF

    # Get the key ID
    KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$email" | grep sec | awk '{print $2}' | cut -d'/' -f2)
    echo "✓ GPG key generated: $KEY_ID"
fi

echo ""
echo "Configuring Git to use GPG key..."

# Update gitconfig files with the key ID
# For personal config
if grep -q "signingkey = #" ~/.gitconfig-personal 2>/dev/null; then
    sed -i '' "s/signingkey = #.*/signingkey = $KEY_ID/" ~/.gitconfig-personal
    echo "✓ Updated ~/.gitconfig-personal with signing key"
elif ! grep -q "signingkey" ~/.gitconfig-personal 2>/dev/null; then
    # Add signingkey if it doesn't exist
    echo "	signingkey = $KEY_ID" >> ~/.gitconfig-personal
    echo "✓ Added signing key to ~/.gitconfig-personal"
fi

# For work config (use same key since user chose single key approach)
if [[ -f ~/.gitconfig-work ]]; then
    if grep -q "signingkey = #" ~/.gitconfig-work 2>/dev/null; then
        sed -i '' "s/signingkey = #.*/signingkey = $KEY_ID/" ~/.gitconfig-work
        echo "✓ Updated ~/.gitconfig-work with signing key"
    elif ! grep -q "signingkey" ~/.gitconfig-work 2>/dev/null; then
        echo "	signingkey = $KEY_ID" >> ~/.gitconfig-work
        echo "✓ Added signing key to ~/.gitconfig-work"
    fi
fi

echo ""
echo "GPG setup complete!"
echo ""
echo "Next steps:"
echo "  1. Export your public key and add to GitHub:"
echo "     gpg --armor --export $KEY_ID | pbcopy"
echo "     Then go to: GitHub Settings → SSH and GPG keys → New GPG key"
echo ""
echo "  2. Test with a signed commit:"
echo "     cd ~/personal/test-repo"
echo "     git commit --allow-empty -S -m 'Test signed commit'"
echo "     git log --show-signature -1"
