#!/usr/bin/env bash
# Display GPG key and configuration information

echo "GPG Secret Keys:"
echo "================"
gpg --list-secret-keys --keyid-format=long

echo ""
echo "Git Signing Configuration:"
echo "=========================="
echo ""
echo "Personal repos (~/personal/*):"
profile_key=$(git config --file ~/.gitconfig-personal user.signingkey 2>/dev/null)
signing=$(git config --file ~/.gitconfig-personal commit.gpgsign 2>/dev/null)
echo "  Signing key: ${profile_key:-Not set}"
echo "  Auto-sign: ${signing:-false}"

echo ""
echo "Work repos (~/work/*):"
work_key=$(git config --file ~/.gitconfig-work user.signingkey 2>/dev/null)
work_signing=$(git config --file ~/.gitconfig-work commit.gpgsign 2>/dev/null)
echo "  Signing key: ${work_key:-Not set}"
echo "  Auto-sign: ${work_signing:-false}"
