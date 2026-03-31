#!/usr/bin/env bash
# Remove zsh caches, automation logs, and .DS_Store files from the repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

DRY_RUN=false
QUIET=false

for _arg in "$@"; do
  [[ "$_arg" == "--quiet" ]] && QUIET=true
done

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run] [--quiet]

Remove zsh caches, automation log files, and .DS_Store files from the repo.
EOF
}

parse_standard_args usage --accept-dry-run "$@"

if ! $QUIET; then
  print_header "Clean"
  $DRY_RUN && print_warning "DRY RUN"
fi

cleaned=0

# Zsh cache
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if [[ -d "$cache_dir" ]]; then
  if $DRY_RUN; then print_step "Zsh cache" warning "would remove"
  else rm -rf "$cache_dir"; print_step "Zsh cache" success "removed"; fi
  cleaned=$((cleaned + 1))
else
  print_step "Zsh cache" skip "not found"
fi

# Automation logs
log_dir="$HOME/.local/log"
if [[ -d "$log_dir" ]]; then
  shopt -s nullglob
  log_files=("$log_dir"/dotfiles-*.log "$log_dir"/repo-update*.log)
  shopt -u nullglob
  if [[ ${#log_files[@]} -gt 0 ]]; then
    if $DRY_RUN; then print_step "Automation logs" warning "would remove ${#log_files[@]} file(s)"
    else rm -f "${log_files[@]}"; print_step "Automation logs" success "${#log_files[@]} file(s) removed"; fi
    cleaned=$((cleaned + 1))
  else
    print_step "Automation logs" skip "none found"
  fi
else
  print_step "Automation logs" skip "no log directory"
fi

# .DS_Store in repo
ds_count=$(find "$DOTFILES" -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$ds_count" -gt 0 ]]; then
  if $DRY_RUN; then print_step ".DS_Store files" warning "would remove $ds_count file(s)"
  else find "$DOTFILES" -name ".DS_Store" -delete; print_step ".DS_Store files" success "$ds_count file(s) removed"; fi
  cleaned=$((cleaned + 1))
else
  print_step ".DS_Store files" skip "none found"
fi

if ! $QUIET; then
  printf '\n'
  if $DRY_RUN; then print_info "Dry run complete"
  elif [[ $cleaned -gt 0 ]]; then print_success "Clean complete"
  else print_success "Already clean"
  fi
fi
