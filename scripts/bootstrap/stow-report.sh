#!/usr/bin/env bash
# Preview stow conflicts without making changes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
STOW_DIR="$DOTFILES/stow"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color]

Preview stow operations and report package conflicts.
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
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
  require_cmd "stow" "Install stow: brew install stow" >/dev/null || {
    print_error "GNU Stow is required"
    exit 1
  }

  print_header "Stow Conflict Report"

  local pkg_dir pkg output conflict_count=0 ok_count=0
  for pkg_dir in "$STOW_DIR"/*/; do
    pkg="$(basename "$pkg_dir")"
    if output=$(stow -n -d "$STOW_DIR" -t "$HOME" "$pkg" 2>&1); then
      print_success "$pkg"
      ok_count=$((ok_count + 1))
      continue
    fi

    if [[ "$output" == *"would cause conflicts"* ]]; then
      print_warning "$pkg has conflicts"
      print_dim "    Run: stow -d $STOW_DIR -t \"$HOME\" \"$pkg\""
      conflict_count=$((conflict_count + 1))
    else
      print_error "$pkg failed preview"
      print_dim "    $output"
      conflict_count=$((conflict_count + 1))
    fi
  done

  echo ""
  print_key_value "Packages OK" "$ok_count"
  print_key_value "Packages with conflicts" "$conflict_count"

  if [[ $conflict_count -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
