#!/usr/bin/env bash
# Remove zsh caches, automation logs, and .DS_Store files from the repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Remove zsh caches, automation log files, and .DS_Store files from the repo.
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

clean_zsh_cache() {
  print_section "Zsh cache..."
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

  if [[ ! -d "$cache_dir" ]]; then
    print_dim "    No zsh cache found"
    return 0
  fi

  if $DRY_RUN; then
    print_info "Would remove: $cache_dir"
  else
    rm -rf "$cache_dir"
    print_success "Removed $cache_dir (regenerates on next shell start)"
  fi
}

clean_logs() {
  print_section "Automation logs..."
  local log_dir="$HOME/.local/log"

  if [[ ! -d "$log_dir" ]]; then
    print_dim "    No log directory found"
    return 0
  fi

  local count=0
  shopt -s nullglob
  local files=("$log_dir"/dotfiles-*.log "$log_dir"/repo-update*.log)
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    print_dim "    No log files found"
    return 0
  fi

  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    if $DRY_RUN; then
      print_info "Would remove: $f"
    else
      rm "$f"
      count=$((count + 1))
    fi
  done

  if ! $DRY_RUN; then
    print_success "Removed $count log file(s)"
  fi
}

clean_ds_store() {
  print_section ".DS_Store files in repo..."

  local files
  files=$(find "$DOTFILES" -name ".DS_Store" 2>/dev/null) || true

  if [[ -z "$files" ]]; then
    print_dim "    None found"
    return 0
  fi

  local count
  count=$(echo "$files" | wc -l | tr -d ' ')

  if $DRY_RUN; then
    echo "$files" | while IFS= read -r f; do
      print_info "Would remove: $f"
    done
  else
    find "$DOTFILES" -name ".DS_Store" -delete
    print_success "Removed $count .DS_Store file(s)"
  fi
}

main() {
  parse_args "$@"

  if $DRY_RUN; then
    print_header "Clean (dry run)"
  else
    print_header "Clean"
  fi

  clean_zsh_cache
  clean_logs
  clean_ds_store

  printf '\n'
  if $DRY_RUN; then
    print_info "Dry run complete — no files were removed"
  else
    print_success "Clean complete"
  fi
}

main "$@"
