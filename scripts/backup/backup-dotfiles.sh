#!/usr/bin/env bash
# Backup current dotfiles before stowing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Create a timestamped backup of local dotfile files before stow operations.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

parse_args "$@"

BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

print_header "Backing Up Dotfiles"

# Files that might be replaced by stow
FILES_TO_BACKUP=(
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/.zshenv"
  "$HOME/.gitconfig"
  "$HOME/.gitignore_global"
  "$HOME/.vimrc"
  "$HOME/.ssh/config"
)

print_section "Creating backup..."
printf '\n'
backed_up_count=0

for file in "${FILES_TO_BACKUP[@]}"; do
  if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
    # Only backup real files, not symlinks
    cp -p "$file" "$BACKUP_DIR/"
    printf "  "
    print_success "$(basename "$file")"
    backed_up_count=$((backed_up_count + 1))
  fi
done

if [[ $backed_up_count -eq 0 ]]; then
  print_info "No files to backup (all are symlinks or don't exist)"
  # Keep a timestamped backup record so health checks can still verify recency.
  cat > "$BACKUP_DIR/README.txt" << EOF
No regular files were backed up at $(date '+%Y-%m-%d %H:%M:%S').
This host appears to be fully stow-managed (symlink-based).
EOF
  echo "$BACKUP_DIR" > "$BACKUP_ROOT/latest"
  printf "  "
  print_success "Recorded empty-state backup: $BACKUP_DIR"
else
  echo "$BACKUP_DIR" > "$BACKUP_ROOT/latest"
  printf '\n'
  print_success "Backup created: $BACKUP_DIR"

  # Rotate old backups - keep last 7 days
  printf '\n'
  print_section "Rotating old backups..."

  OLD_BACKUPS=$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "202*" -mtime +7 2>/dev/null || true)

  if [[ -n "$OLD_BACKUPS" ]]; then
    removed_count=0
    while IFS= read -r old_backup; do
      rm -rf "$old_backup"
      printf "  "
      print_dim "Removed: $(basename "$old_backup")"
      removed_count=$((removed_count + 1))
    done <<< "$OLD_BACKUPS"
    printf '\n'
    print_info "Removed $removed_count old backup(s)"
  else
    print_success "No old backups to remove (keeping last 7 days)"
  fi

  # Compress if large
  BACKUP_SIZE=$(du -sm "$BACKUP_DIR" 2>/dev/null | cut -f1)
  if [[ $BACKUP_SIZE -gt 10 ]]; then
    printf '\n'
    print_section "Compressing large backup..."
    tar -czf "$BACKUP_DIR.tar.gz" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")" 2>/dev/null
    rm -rf "$BACKUP_DIR"
    printf "  "
    print_success "Compressed to $(basename "$BACKUP_DIR").tar.gz"
  fi
fi

printf '\n'
