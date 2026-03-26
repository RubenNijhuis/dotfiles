#!/usr/bin/env bash
# Remove zsh caches, automation logs, and .DS_Store files from the repo.
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

Remove zsh caches, automation log files, and .DS_Store files from the repo.
EOF
}

parse_standard_args usage --accept-dry-run "$@"

print_header "Clean"
$DRY_RUN && print_warning "DRY RUN"

# Zsh cache
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if [[ -d "$cache_dir" ]]; then
  if $DRY_RUN; then print_info "Would remove: $cache_dir"
  else rm -rf "$cache_dir"; print_success "Removed zsh cache"; fi
fi

# Automation logs
log_dir="$HOME/.local/log"
if [[ -d "$log_dir" ]]; then
  shopt -s nullglob
  log_files=("$log_dir"/dotfiles-*.log "$log_dir"/repo-update*.log)
  shopt -u nullglob
  if [[ ${#log_files[@]} -gt 0 ]]; then
    if $DRY_RUN; then print_info "Would remove ${#log_files[@]} log file(s)"
    else rm -f "${log_files[@]}"; print_success "Removed ${#log_files[@]} log file(s)"; fi
  fi
fi

# .DS_Store in repo
ds_count=$(find "$DOTFILES" -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$ds_count" -gt 0 ]]; then
  if $DRY_RUN; then print_info "Would remove $ds_count .DS_Store file(s)"
  else find "$DOTFILES" -name ".DS_Store" -delete; print_success "Removed $ds_count .DS_Store file(s)"; fi
fi

printf '\n'
if $DRY_RUN; then print_info "Dry run complete"; else print_success "Clean complete"; fi
