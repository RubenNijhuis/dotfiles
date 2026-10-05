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

Preview or restore machine-specific files from the latest local snapshot.
The default restore requires confirmation; --dry-run makes no changes.
EOF
}

# Map backup paths back to their original locations.
resolve_destination() {
  local rel_path="$1"
  case "$rel_path" in
    .ssh/*) printf '%s\n' "$HOME/$rel_path" ;;
    local/*) printf '%s\n' "${DOTFILES_BACKUP_LOCAL_DIR:-$DOTFILES/local}/${rel_path#local/}" ;;
    local.sh) printf '%s\n' "$HOME/.config/shell/local.sh" ;;
    common.conf) printf '%s\n' "$HOME/.gnupg/common.conf" ;;
    .zshrc|.zshenv|.bashrc|.bash_profile|.profile) printf '%s\n' "$HOME/$rel_path" ;;
    *) print_error "Unrecognized backup path: $rel_path" >&2; return 1 ;;
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

  # Do not extract archives as a side effect of a preview. Historical archives
  # require a separately reviewed extraction before updating the latest pointer.
  local backup_dir="$backup_path"
  if [[ "$backup_path" == *.tar.gz ]]; then
    print_error "Legacy archive: review and unpack separately before restoring"
    exit 1
  fi

  if [[ ! -d "$backup_dir" || -L "$backup_dir" || -L "$HOME/.dotfiles-backup" ]]; then
    print_error "Backup directory not found or is symlinked: $backup_dir"
    exit 1
  fi
  case "$backup_dir" in
    "$HOME/.dotfiles-backup/"*) ;;
    *) print_error "Backup directory not found inside the local backup root"; exit 1 ;;
  esac
  [[ "$backup_dir" != *'/../'* && "$backup_dir" != */.. ]] || {
    print_error "Unsafe backup directory"; exit 1;
  }

  print_header "Restore Backup"
  print_info "Restoring from: $backup_dir"
  printf '\n'

  # Collect all files with their destinations
  local sources=() destinations=()
  while IFS= read -r -d '' file; do
    local rel_path="${file#"$backup_dir"/}"
    local dest
    dest="$(resolve_destination "$rel_path")"
    sources+=("$file")
    destinations+=("$dest")
  done < <(find "$backup_dir" -type f ! -name 'README.txt' -print0)

  if [[ ${#sources[@]} -eq 0 ]]; then
    print_warning "No files to restore"
    exit 0
  fi

  print_section "Files to restore:"
  for dest in "${destinations[@]}"; do
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

  umask 077
  local i
  # Preflight all destinations before copying any file. Never overwrite Nix
  # links or follow a symlinked parent into another location.
  for dest in "${destinations[@]}"; do
    local parent="$dest"
    while [[ "$parent" != / && "$parent" != . ]]; do
      [[ ! -L "$parent" ]] || {
        print_error "Refusing symlinked restore destination: $parent"; exit 1;
      }
      parent="$(dirname "$parent")"
    done
  done
  for ((i = 0; i < ${#sources[@]}; i++)); do
    local src="${sources[$i]}" dest="${destinations[$i]}"
    mkdir -p "$(dirname "$dest")"
    cp -p "$src" "$dest"
    chmod 600 "$dest"
    printf "  "
    print_success "Restored $(basename "$dest") → $dest"
  done

  print_success "Restore complete"
}

main "$@"
