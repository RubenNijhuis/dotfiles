#!/usr/bin/env bash
# Full clean: dotfiles backups and Homebrew cache (runs after clean.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Remove dotfiles backup directories and Homebrew download cache.
Run after clean.sh for a full cleanup.
EOF
}

clean_dotfiles_backups() {
  print_section "Dotfiles backups..."

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
  elif $DRY_RUN; then
    print_info "Found $found backup clone(s)"
  else
    print_success "Removed $removed backup clone(s)"
  fi
}

clean_brew_cache() {
  print_section "Homebrew cache..."

  if ! command -v brew &>/dev/null; then
    print_warning "brew not found, skipping"
    return 0
  fi

  if $DRY_RUN; then
    print_info "Would run: brew cleanup --prune=all"
  else
    brew cleanup --prune=all
    print_success "Homebrew cache cleared"
  fi
}

main() {
  parse_standard_args usage --accept-dry-run "$@"

  if $DRY_RUN; then
    print_header "Clean All (dry run)"
  else
    print_header "Clean All"
  fi

  clean_dotfiles_backups
  clean_brew_cache

  printf '\n'
  if $DRY_RUN; then
    print_info "Dry run complete — no files were removed"
  else
    print_success "Full clean complete"
  fi
}

main "$@"
