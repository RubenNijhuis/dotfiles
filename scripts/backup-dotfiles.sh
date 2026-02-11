#!/usr/bin/env bash
# Backup current dotfiles before stowing
set -euo pipefail

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Files that might be replaced by stow
FILES_TO_BACKUP=(
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/.zshenv"
  "$HOME/.p10k.zsh"
  "$HOME/.gitconfig"
  "$HOME/.gitignore_global"
  "$HOME/.vimrc"
  "$HOME/.ssh/config"
)

echo "Creating backup in $BACKUP_DIR"
backed_up_count=0

for file in "${FILES_TO_BACKUP[@]}"; do
  if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
    # Only backup real files, not symlinks
    cp -p "$file" "$BACKUP_DIR/"
    echo "  ✓ Backed up $(basename "$file")"
    ((backed_up_count++))
  fi
done

if [[ $backed_up_count -eq 0 ]]; then
  echo "  No files to backup (all are symlinks or don't exist)"
  rm -rf "$BACKUP_DIR"
else
  echo "$BACKUP_DIR" > "$HOME/.dotfiles-backup/latest"
  echo "Backup complete: $BACKUP_DIR"
fi
