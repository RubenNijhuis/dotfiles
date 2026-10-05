#!/usr/bin/env bash
# Local rollback snapshots, not encrypted or off-device recovery backups.
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
SSH files, GPG common.conf (not private keys), and shell local config.
Snapshots contain sensitive plaintext, stay on this disk, and are never
automatically deleted. They are not a substitute for an encrypted backup.
EOF
}

parse_standard_args usage "$@"

BACKUP_ROOT="$HOME/.dotfiles-backup"
umask 077
[[ ! -L "$BACKUP_ROOT" && ! -L "$BACKUP_ROOT/latest" ]] || {
  print_error "Refusing a symlinked backup root or latest pointer"; exit 1;
}
mkdir -p "$BACKUP_ROOT"
chmod 700 "$BACKUP_ROOT"
BACKUP_DIR="$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S).XXXXXX")"

# Directories to back up (preserving structure)
DIRS_TO_BACKUP=(
  "${DOTFILES_BACKUP_LOCAL_DIR:-$DOTFILES/local}"
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
  if [[ -d "$dir" && ! -L "$dir" ]]; then
    # The optional local directory override isolates test fixtures.
    local_name=local
    [[ "$dir" != "$HOME/.ssh" ]] || local_name=.ssh
    mkdir -p "$BACKUP_DIR/$local_name"
    # Capture enumeration status: process substitution alone hides find errors.
    file_list="$BACKUP_DIR/.file-list"
    find "$dir" -type f ! -name '*.example' ! -name '.gitkeep' \
      ! -name 'README.md' -print0 > "$file_list"
    # Never follow symlinks; retain nested paths and matching public keys.
    while IFS= read -r -d '' file; do
      destination="$BACKUP_DIR/$local_name/${file#"$dir"/}"
      mkdir -p "$(dirname "$destination")"
      cp -p "$file" "$destination"
      chmod 600 "$destination"
      backed_up=$((backed_up + 1))
    done < "$file_list"
    rm "$file_list"
  fi
done

# Back up individual files
for file in "${FILES_TO_BACKUP[@]}"; do
  if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
    cp -p "$file" "$BACKUP_DIR/"
    chmod 600 "$BACKUP_DIR/$(basename "$file")"
    backed_up=$((backed_up + 1))
  fi
done

if [[ $backed_up -eq 0 ]]; then
  echo "No machine-specific files found to back up" > "$BACKUP_DIR/README.txt"
fi

printf '%s\n' "$BACKUP_DIR" > "$BACKUP_ROOT/latest"
chmod 600 "$BACKUP_ROOT/latest"
print_success "Backup: $BACKUP_DIR ($backed_up file(s))"
print_warning "Local plaintext rollback only; no off-device recovery or automatic pruning"

notify "Dotfiles Backup" "Backup completed successfully"
