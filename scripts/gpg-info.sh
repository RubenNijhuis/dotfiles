#!/usr/bin/env bash
# Display GPG key and configuration information

echo "GPG Secret Keys:"
echo "================"
gpg --list-secret-keys --keyid-format=long

echo ""
echo "Git Signing Configuration:"
echo "=========================="
signing_key=$(git config user.signingkey 2>/dev/null)
signing=$(git config commit.gpgsign 2>/dev/null)
echo "  Signing key: ${signing_key:-Not set}"
echo "  Auto-sign: ${signing:-false}"
