#!/usr/bin/env bash
# Create a timestamped backup of local dotfiles before stow operations.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Create a timestamped backup of local dotfile files before stow operations.
EOF
}

parse_standard_args usage "$@"

BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

FILES_TO_BACKUP=(
  "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zshenv"
  "$HOME/.gitconfig" "$HOME/.gitignore_global" "$HOME/.vimrc"
  "$HOME/.ssh/config"
)

backed_up=0
for file in "${FILES_TO_BACKUP[@]}"; do
  if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
    cp -p "$file" "$BACKUP_DIR/"
    backed_up=$((backed_up + 1))
  fi
done

if [[ $backed_up -eq 0 ]]; then
  echo "No regular files to back up (all symlinks)" > "$BACKUP_DIR/README.txt"
fi

echo "$BACKUP_DIR" > "$BACKUP_ROOT/latest"
print_success "Backup: $BACKUP_DIR ($backed_up file(s))"

# Rotate old backups (keep last 7 days)
old=$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "202*" -mtime +7 2>/dev/null || true)
if [[ -n "$old" ]]; then
  count=$(echo "$old" | wc -l | xargs)
  echo "$old" | xargs rm -rf
  print_info "Rotated $count old backup(s)"
fi

# Compress if large
size=$(du -sm "$BACKUP_DIR" 2>/dev/null | cut -f1)
if [[ "${size:-0}" -gt 10 ]]; then
  tar -czf "$BACKUP_DIR.tar.gz" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
  rm -rf "$BACKUP_DIR"
  print_info "Compressed to $(basename "$BACKUP_DIR").tar.gz"
fi

notify "Dotfiles Backup" "Backup completed successfully"
