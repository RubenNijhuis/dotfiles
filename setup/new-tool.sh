#!/usr/bin/env bash
# Scaffold a new chezmoi-managed config file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/output.sh" "$@"
source "$DOTFILES/lib/cli.sh"

usage() {
  cat <<USAGE
Usage: $0 [--help] [--no-color] <tool-name>

Scaffold a chezmoi-managed config for <tool-name> at
chezmoi/dot_config/<tool-name>/config. After editing, run 'make apply'.
USAGE
}

show_help_if_requested usage "$@"

TOOL_NAME=""
for arg in "$@"; do
  case "$arg" in
    --no-color|--help|-h) ;;
    -*) print_error "Unknown argument: $arg"; usage; exit 1 ;;
    *) TOOL_NAME="$arg" ;;
  esac
done
[[ -z "$TOOL_NAME" ]] && { usage; exit 1; }

target="$DOTFILES/chezmoi/dot_config/$TOOL_NAME"
[[ -d "$target" ]] && { print_error "Already exists at $target"; exit 1; }

mkdir -p "$target"
touch "$target/config"
print_success "Created $target/config"
print_info "Next: edit the file, then run 'make apply' (chezmoi apply)."
