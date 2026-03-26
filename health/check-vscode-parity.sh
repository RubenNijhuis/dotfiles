#!/usr/bin/env bash
# Check parity between extensions.txt and Brewfile.vscode
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

EXTENSIONS_TXT="$DOTFILES/config/vscode/Library/Application Support/Code/User/extensions.txt"
BREWFILE_VSCODE="$DOTFILES/brew/Brewfile.vscode"
CHECK_MODE=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--check]

Verify VS Code extension parity between extensions.txt and Brewfile.vscode.

Options:
  --check     Exit non-zero if drift is detected (for CI/Makefile use)
  --no-color  Disable colored output
  --help      Show this help message
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --check)
        CHECK_MODE=true
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

extract_extensions_txt() {
  grep -v '^#' "$EXTENSIONS_TXT" | grep -v '^[[:space:]]*$' | sed 's/#.*//' | awk '{print $1}' | sort
}

extract_brewfile_vscode() {
  grep '^vscode ' "$BREWFILE_VSCODE" | sed 's/^vscode "//' | sed 's/".*//' | sort
}

parse_args "$@"

print_header "VS Code Extension Parity Check"

tmp_ext="$(mktemp)"
tmp_brew="$(mktemp)"
trap 'rm -f "$tmp_ext" "$tmp_brew"' EXIT

extract_extensions_txt > "$tmp_ext"
extract_brewfile_vscode > "$tmp_brew"

only_in_ext="$(comm -23 "$tmp_ext" "$tmp_brew")"
only_in_brew="$(comm -13 "$tmp_ext" "$tmp_brew")"

DRIFT=0

if [[ -n "$only_in_ext" ]]; then
  DRIFT=1
  print_warning "Only in extensions.txt (missing from Brewfile.vscode):"
  while IFS= read -r ext; do
    print_bullet "$ext"
  done <<< "$only_in_ext"
  echo
fi

if [[ -n "$only_in_brew" ]]; then
  DRIFT=1
  print_warning "Only in Brewfile.vscode (missing from extensions.txt):"
  while IFS= read -r ext; do
    print_bullet "$ext"
  done <<< "$only_in_brew"
  echo
fi

if [[ "$DRIFT" -eq 0 ]]; then
  print_success "Extensions are in sync ($(wc -l < "$tmp_ext" | xargs) extensions)"
else
  if $CHECK_MODE; then
    print_error "Extension drift detected"
    exit 1
  else
    print_warning "Extension drift detected — fix manually or run brew-sync"
  fi
fi
