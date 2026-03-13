#!/usr/bin/env bash
# Full clean: dotfiles backups and Homebrew cache (runs after clean.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Remove dotfiles backup directories and Homebrew download cache.
Run after clean.sh for a full cleanup.
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

clean_dotfiles_backups() {
  print_section "Dotfiles backups..."

  local args=()
  $DRY_RUN && args+=(--dry-run)

  bash "$SCRIPT_DIR/cleanup-dotfiles-backups.sh" "${args[@]}"
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
  parse_args "$@"

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
