#!/usr/bin/env bash
# Install VS Code extensions from extensions.txt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help]

Install VS Code extensions declared in stow/vscode/.../extensions.txt.
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

DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXTENSIONS_FILE="$DOTFILES/stow/vscode/Library/Application Support/Code/User/extensions.txt"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
  echo "Error: extensions.txt not found at $EXTENSIONS_FILE" >&2
  exit 1
fi

if ! command -v code &>/dev/null; then
  echo "Error: 'code' command not found. Is VS Code installed?" >&2
  exit 1
fi

echo "Installing VS Code extensions..."
failed=0
total=0
while IFS= read -r ext; do
  total=$((total + 1))
  if ! code --install-extension "$ext" >/dev/null 2>&1; then
    echo "  ✗ Failed: $ext" >&2
    failed=$((failed + 1))
  fi
done < <(grep -v '^#' "$EXTENSIONS_FILE" | grep -v '^$' | cut -d' ' -f1)

installed=$((total - failed))
echo "✓ $installed/$total extensions installed"
if [[ $failed -gt 0 ]]; then
  echo "⚠ $failed extensions failed to install" >&2
fi
