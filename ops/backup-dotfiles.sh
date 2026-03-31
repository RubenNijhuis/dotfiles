#!/usr/bin/env bash
# Back up machine-specific files that are not tracked by git.
# These are the files you can't recover from a fresh clone.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Back up machine-specific files not tracked by git: local overrides,
SSH keys, GPG keys, and shell local config.
EOF
}

parse_standard_args usage "$@"

BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Directories to back up (preserving structure)
DIRS_TO_BACKUP=(
  "$DOTFILES/local"
  "$HOME/.ssh"
)

# Individual files to back up
FILES_TO_BACKUP=(
  "$HOME/.config/shell/local.sh"
  "$HOME/.gnupg/common.conf"
)

backed_up=0

# Back up directories
for dir in "${DIRS_TO_BACKUP[@]}"; do
  if [[ -d "$dir" ]]; then
    local_name=$(basename "$dir")
    mkdir -p "$BACKUP_DIR/$local_name"
    # Copy files only, skip symlinks and examples
    find "$dir" -maxdepth 2 -type f \
      ! -name '*.example' ! -name '.gitkeep' ! -name 'README.md' \
      ! -name '*.pub' \
      -exec cp -p {} "$BACKUP_DIR/$local_name/" \; 2>/dev/null
    count=$(find "$BACKUP_DIR/$local_name" -type f 2>/dev/null | wc -l | xargs)
    backed_up=$((backed_up + count))
  fi
done

# Back up individual files
for file in "${FILES_TO_BACKUP[@]}"; do
  if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
    cp -p "$file" "$BACKUP_DIR/"
    backed_up=$((backed_up + 1))
  fi
done

if [[ $backed_up -eq 0 ]]; then
  echo "No machine-specific files found to back up" > "$BACKUP_DIR/README.txt"
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
  echo "$BACKUP_DIR.tar.gz" > "$BACKUP_ROOT/latest"
  print_info "Compressed to $(basename "$BACKUP_DIR").tar.gz"
fi

notify "Dotfiles Backup" "Backup completed successfully"
