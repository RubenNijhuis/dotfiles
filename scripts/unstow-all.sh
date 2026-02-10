#!/usr/bin/env bash
# Unstow all config packages
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$DOTFILES/stow"

for pkg_dir in "$STOW_DIR"/*/; do
    pkg="$(basename "$pkg_dir")"
    echo "Unstowing: $pkg"
    stow -d "$STOW_DIR" -t "$HOME" -D "$pkg"
done

echo "All packages unstowed."
