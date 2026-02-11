#!/usr/bin/env bash
# Stow all config packages from stow/ into ~
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$DOTFILES/stow"

# Backup existing files before stowing
if [[ -f "$DOTFILES/scripts/backup-dotfiles.sh" ]]; then
  bash "$DOTFILES/scripts/backup-dotfiles.sh"
fi

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

    if stow -d "$STOW_DIR" -t "$HOME" "$pkg" 2>&1; then
        echo "  ✓ $pkg stowed successfully"
    else
        echo "  ✗ Failed to stow $pkg"
        echo "  Run 'make unstow' and try again, or check for conflicts"
        exit 1
    fi
done

echo "All packages stowed."
