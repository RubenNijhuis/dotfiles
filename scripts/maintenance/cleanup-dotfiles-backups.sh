#!/usr/bin/env bash
# Remove old dotfiles backup clones from $HOME.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Remove directories matching \$HOME/dotfiles.backup.*.
EOF
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
  print_header "Dotfiles Backup Cleanup"

  local found=0 removed=0
  shopt -s nullglob
  for path in "$HOME"/dotfiles.backup.*; do
    [[ -d "$path" ]] || continue
    found=$((found + 1))
    if $DRY_RUN; then
      print_info "Would remove: $path"
      continue
    fi
    rm -r "$path"
    print_success "Removed: $path"
    removed=$((removed + 1))
  done
  shopt -u nullglob

  if [[ $found -eq 0 ]]; then
    print_success "No backup clones found"
    return 0
  fi

  if $DRY_RUN; then
    print_info "Found $found backup clone(s)"
  else
    print_success "Removed $removed backup clone(s)"
  fi
}

main "$@"
