#!/usr/bin/env bash
# Restore from latest backup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
DRY_RUN=false

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--dry-run]

Restore files from the latest backup recorded in ~/.dotfiles-backup/latest.
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --dry-run)
        DRY_RUN=true
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

main() {
  parse_args "$@"

  local latest_backup="$HOME/.dotfiles-backup/latest"
  if [[ ! -f "$latest_backup" ]]; then
    print_error "No backup found"
    exit 1
  fi

  local backup_dir
  backup_dir="$(cat "$latest_backup")"
  if [[ ! -d "$backup_dir" ]]; then
    print_error "Backup directory not found: $backup_dir"
    exit 1
  fi

  print_header "Restore Backup"
  print_info "Restoring from: $backup_dir"
  echo
  print_section "Files to restore:"
  ls -1 "$backup_dir"
  echo

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
