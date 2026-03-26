#!/usr/bin/env bash
# Scaffold a new config package for a tool.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 <name> [--brew <formula>] [--cask <cask>] [--config-dir] [--help] [--no-color]

Scaffold a new config package.

Options:
  --brew <formula>  Add a brew formula to Brewfile.cli
  --cask <cask>     Add a cask to Brewfile.apps
  --config-dir      Create .config/<name>/ structure
  --no-color        Disable colored output
  --help, -h        Show this help message
EOF
}

TOOL_NAME="" BREW_FORMULA="" BREW_CASK="" CONFIG_DIR=false

show_help_if_requested usage "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brew)  BREW_FORMULA="$2"; shift 2 ;;
    --cask)  BREW_CASK="$2"; shift 2 ;;
    --config-dir) CONFIG_DIR=true; shift ;;
    --no-color) shift ;;
    -*) print_error "Unknown option: $1"; usage; exit 1 ;;
    *)
      if [[ -z "$TOOL_NAME" ]]; then TOOL_NAME="$1"; else print_error "Unexpected argument: $1"; exit 1; fi
      shift ;;
  esac
done

[[ -z "$TOOL_NAME" ]] && { print_error "Tool name is required"; usage; exit 1; }

stow_dir="$DOTFILES/config/$TOOL_NAME"
[[ -d "$stow_dir" ]] && { print_error "Package '$TOOL_NAME' already exists at $stow_dir"; exit 1; }

if $CONFIG_DIR; then
  mkdir -p "$stow_dir/.config/$TOOL_NAME"
else
  mkdir -p "$stow_dir"
fi
print_success "Created config/$TOOL_NAME/"

if [[ -n "$BREW_FORMULA" ]]; then
  if ! grep -q "\"$BREW_FORMULA\"" "$DOTFILES/brew/Brewfile.cli" 2>/dev/null; then
    echo "brew \"$BREW_FORMULA\"" >> "$DOTFILES/brew/Brewfile.cli"
    print_success "Added brew \"$BREW_FORMULA\" to Brewfile.cli"
  fi
fi

if [[ -n "$BREW_CASK" ]]; then
  if ! grep -q "\"$BREW_CASK\"" "$DOTFILES/brew/Brewfile.apps" 2>/dev/null; then
    echo "cask \"$BREW_CASK\"" >> "$DOTFILES/brew/Brewfile.apps"
    print_success "Added cask \"$BREW_CASK\" to Brewfile.apps"
  fi
fi

printf '\n'
print_info "Next: add config files, then run 'make stow'"
