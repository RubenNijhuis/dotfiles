#!/usr/bin/env bash
# Full clean: standard clean + log rotation + backups + Homebrew cache.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Full cleanup: zsh cache, logs, .DS_Store, old backups, and Homebrew cache.
EOF
}

main() {
  parse_standard_args usage --accept-dry-run "$@"

  print_header "Clean All"
  $DRY_RUN && print_warning "DRY RUN"

  # Run standard clean (zsh cache, automation logs, .DS_Store)
  local clean_args=(--quiet)
  $DRY_RUN && clean_args+=(--dry-run)
  bash "$SCRIPT_DIR/clean.sh" "${clean_args[@]}"

  # Rotate old automation logs
  if $DRY_RUN; then
    print_step "Log rotation" skip "dry run"
  else
    if bash "$SCRIPT_DIR/cleanup-logs.sh" &>/dev/null; then
      print_step "Log rotation" success "cleaned"
    else
      print_step "Log rotation" skip "nothing to rotate"
    fi
  fi

  # Dotfiles backups
  local backup_root="$HOME/.dotfiles-backup"
  shopt -s nullglob
  local backup_dirs=("$backup_root"/202*)
  shopt -u nullglob
  if [[ ${#backup_dirs[@]} -gt 0 ]]; then
    if $DRY_RUN; then
      print_step "Old backups" warning "would remove ${#backup_dirs[@]}"
    else
      rm -rf "${backup_dirs[@]}"
      print_step "Old backups" success "${#backup_dirs[@]} removed"
    fi
  else
    print_step "Old backups" skip "none found"
  fi

  # Homebrew cache
  if command -v brew &>/dev/null; then
    if $DRY_RUN; then
      print_step "Homebrew cache" warning "would clean"
    else
      brew cleanup --prune=all &>/dev/null
      print_step "Homebrew cache" success "cleaned"
    fi
  else
    print_step "Homebrew cache" skip "brew not found"
  fi

  printf '\n'
  if $DRY_RUN; then print_info "Dry run complete — no files were removed"
  else print_success "Full clean complete"
  fi
}

main "$@"
