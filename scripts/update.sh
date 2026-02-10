#!/usr/bin/env bash
# Update brew packages and re-stow configs
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

echo "Updating Homebrew..."
brew update && brew upgrade && brew cleanup

echo "Re-stowing configs..."
bash "$DOTFILES/scripts/stow-all.sh"

echo "Update complete."
