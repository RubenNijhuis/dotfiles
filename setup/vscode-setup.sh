#!/usr/bin/env bash
# Install VS Code extensions from extensions.txt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help]

Install VS Code extensions declared in config/vscode/.../extensions.txt.
Skips extensions that are already installed.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

parse_args "$@"

DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
EXTENSIONS_FILE="$DOTFILES/config/vscode/Library/Application Support/Code/User/extensions.txt"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
  print_error "extensions.txt not found at $EXTENSIONS_FILE"
  exit 1
fi

if ! command -v code &>/dev/null; then
  print_error "'code' command not found. Is VS Code installed?"
  exit 1
fi

print_section "Installing VS Code extensions..."
failed=0
total=0
while IFS= read -r ext; do
  total=$((total + 1))
  if ! code --install-extension "$ext" >/dev/null 2>&1; then
    print_error "Failed: $ext"
    failed=$((failed + 1))
  fi
done < <(grep -v '^#' "$EXTENSIONS_FILE" | grep -v '^$' | cut -d' ' -f1)

installed=$((total - failed))
print_success "$installed/$total extensions installed"
if [[ $failed -gt 0 ]]; then
  print_warning "$failed extensions failed to install"
fi
