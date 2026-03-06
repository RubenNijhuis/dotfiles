#!/usr/bin/env bash
# Install VS Code extensions from extensions.txt
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  cat <<EOF
Usage: $0 [--help]

Install VS Code extensions declared in stow/vscode/.../extensions.txt.
Skips extensions that are already installed.
EOF
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
grep -v '^#' "$EXTENSIONS_FILE" | grep -v '^$' | cut -d' ' -f1 | \
  xargs -L 1 code --install-extension
echo "✓ Extensions installed"
