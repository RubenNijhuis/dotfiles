#!/usr/bin/env bash
# Update brew packages and re-stow configs
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

echo "📦 Updating Homebrew..."
brew update && brew upgrade && brew cleanup

echo "🔧 Updating Node (fnm)..."
if command -v fnm &> /dev/null; then
    fnm install --lts
else
    echo "fnm not found, skipping Node update"
fi

echo "📚 Updating global packages..."
if command -v pnpm &> /dev/null; then
    pnpm update -g
else
    echo "pnpm not found, skipping global package update"
fi

echo "🔗 Re-stowing configs..."
bash "$DOTFILES/scripts/stow-all.sh"

echo "✅ Update complete!"
