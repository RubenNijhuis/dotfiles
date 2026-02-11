#!/usr/bin/env bash
# Migrate existing SSH keys to new naming convention

set -euo pipefail

echo "SSH Key Migration"
echo "================="
echo ""

# Check for existing default key
if [[ -f ~/.ssh/id_ed25519 ]]; then
    echo "Found existing SSH key: ~/.ssh/id_ed25519"
    echo "This will be renamed to: ~/.ssh/id_ed25519_personal"
    echo ""
    read -rp "Proceed with migration? [y/N] " confirm

    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
        mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_personal
        mv ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519_personal.pub
        echo "✓ Keys migrated successfully"
        echo ""
        echo "Next steps:"
        echo "  1. Update GitHub/GitLab with the same public key (no change needed)"
        echo "  2. Run: ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal"
        echo "  3. Test: ssh -T git@github.com"
    else
        echo "Migration cancelled"
    fi
else
    echo "No existing id_ed25519 key found"
    echo "You can generate new keys with: make ssh-setup"
fi
