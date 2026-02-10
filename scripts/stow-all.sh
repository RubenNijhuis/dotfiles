#!/usr/bin/env bash
# Stow all config packages from stow/ into ~
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$DOTFILES/stow"

# Clean up old manual symlinks (from pre-stow setup)
OLD_SYMLINKS=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.zshenv"
    "$HOME/.p10k.zsh"
    "$HOME/.gitconfig"
    "$HOME/.gitconfig-personal"
    "$HOME/.gitconfig-work"
    "$HOME/.gitignore_global"
)

for link in "${OLD_SYMLINKS[@]}"; do
    if [[ -L "$link" ]]; then
        target="$(readlink "$link")"
        # Only remove if it points into dotfiles/ (old manual setup)
        if [[ "$target" == *dotfiles/* && "$target" != *dotfiles/stow/* ]]; then
            echo "Removing old symlink: $link -> $target"
            rm "$link"
        fi
    fi
done

# Stow each package
for pkg_dir in "$STOW_DIR"/*/; do
    pkg="$(basename "$pkg_dir")"
    echo "Stowing: $pkg"
    stow -d "$STOW_DIR" -t "$HOME" "$pkg"
done

echo "All packages stowed."
