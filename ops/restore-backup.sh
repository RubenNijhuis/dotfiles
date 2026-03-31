#!/usr/bin/env bash
# Restore from latest backup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Restore machine-specific files from the latest backup.
EOF
}

# Map backup paths back to their original locations.
resolve_destination() {
  local rel_path="$1"
  local filename dir

  filename="$(basename "$rel_path")"
  dir="$(dirname "$rel_path")"

  case "$dir" in
    .ssh)     echo "$HOME/.ssh/$filename" ;;
    local)    echo "$DOTFILES/local/$filename" ;;
    .)
      case "$filename" in
        local.sh)     echo "$HOME/.config/shell/local.sh" ;;
        common.conf)  echo "$HOME/.gnupg/common.conf" ;;
        *)            echo "$HOME/$filename" ;;
      esac
      ;;
    *)        echo "$HOME/$dir/$filename" ;;
  esac
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

  # Collect all files with their destinations
  local files=()
  while IFS= read -r file; do
    local rel_path="${file#"$backup_dir"/}"
    local dest
    dest="$(resolve_destination "$rel_path")"
    files+=("$file|$dest")
  done < <(find "$backup_dir" -type f ! -name 'README.txt' | sort)

  if [[ ${#files[@]} -eq 0 ]]; then
    print_warning "No files to restore"
    exit 0
  fi

  print_section "Files to restore:"
  for entry in "${files[@]}"; do
    local dest="${entry#*|}"
    printf "  %s\n" "$dest"
  done
  printf '\n'

  if $DRY_RUN; then
    print_warning "DRY RUN: no files will be copied"
    exit 0
  fi

  if ! confirm "This will overwrite current files. Continue? [y/N] " "N"; then
    print_warning "Restore cancelled"
    exit 0
  fi

  for entry in "${files[@]}"; do
    local src="${entry%%|*}"
    local dest="${entry#*|}"
    mkdir -p "$(dirname "$dest")"
    cp -p "$src" "$dest"
    printf "  "
    print_success "Restored $(basename "$dest") → $dest"
  done

  print_success "Restore complete"
}

main "$@"
