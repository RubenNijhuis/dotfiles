#!/usr/bin/env bash
# Restore from latest backup
set -euo pipefail

LATEST_BACKUP="$HOME/.dotfiles-backup/latest"

if [[ ! -f "$LATEST_BACKUP" ]]; then
  echo "No backup found"
  exit 1
fi

BACKUP_DIR="$(cat "$LATEST_BACKUP")"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Backup directory not found: $BACKUP_DIR"
  exit 1
fi

echo "Restoring from: $BACKUP_DIR"
echo ""
echo "Files to restore:"
ls -1 "$BACKUP_DIR"
echo ""

read -rp "This will overwrite current files. Continue? [y/N] " confirm
if [[ "${confirm:-N}" =~ ^[Yy] ]]; then
  for file in "$BACKUP_DIR"/*; do
    filename="$(basename "$file")"
    cp -p "$file" "$HOME/"
    echo "  ✓ Restored $filename"
  done
  echo "✓ Restore complete"
else
  echo "Restore cancelled"
fi
