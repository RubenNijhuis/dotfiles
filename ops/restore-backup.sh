#!/usr/bin/env bash
# Restore from latest backup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Restore files from the latest backup recorded in ~/.dotfiles-backup/latest.
EOF
}

main() {
  parse_standard_args usage --accept-dry-run "$@"

  local latest_backup="$HOME/.dotfiles-backup/latest"
  if [[ ! -f "$latest_backup" ]]; then
    print_error "No backup found"
    exit 1
  fi

  local backup_path
  backup_path="$(cat "$latest_backup")"

  # Handle compressed backups
  local backup_dir="$backup_path"
  if [[ "$backup_path" == *.tar.gz && -f "$backup_path" ]]; then
    backup_dir="${backup_path%.tar.gz}"
    if [[ ! -d "$backup_dir" ]]; then
      tar -xzf "$backup_path" -C "$(dirname "$backup_path")"
      print_info "Extracted compressed backup"
    fi
  fi

  if [[ ! -d "$backup_dir" ]]; then
    print_error "Backup directory not found: $backup_dir"
    exit 1
  fi

  print_header "Restore Backup"
  print_info "Restoring from: $backup_dir"
  printf '\n'
  print_section "Files to restore:"
  ls -1 "$backup_dir"
  printf '\n'

  if $DRY_RUN; then
    print_warning "DRY RUN: no files will be copied"
    for file in "$backup_dir"/*; do
      filename="$(basename "$file")"
      printf "  "
      print_dim "Would restore $filename to $HOME/$filename"
    done
    exit 0
  fi

  if ! confirm "This will overwrite current files. Continue? [y/N] " "N"; then
    print_warning "Restore cancelled"
    exit 0
  fi

  local file filename
  for file in "$backup_dir"/*; do
    filename="$(basename "$file")"
    cp -p "$file" "$HOME/"
    printf "  "
    print_success "Restored $filename"
  done

  print_success "Restore complete"
}

main "$@"
