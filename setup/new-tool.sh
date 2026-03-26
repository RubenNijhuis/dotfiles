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

Arguments:
  name              Package name (e.g., ripgrep, lazydocker)

Options:
  --brew <formula>  Add a brew formula to Brewfile.cli
  --cask <cask>     Add a cask to Brewfile.apps
  --config-dir      Create .config/<name>/ structure (default: config in home root)
  --no-color        Disable colored output
  --help, -h        Show this help message

Examples:
  $0 ripgrep --brew ripgrep
  $0 lazydocker --brew lazydocker --config-dir
  $0 wezterm --cask wezterm --config-dir
EOF
}

TOOL_NAME=""
BREW_FORMULA=""
BREW_CASK=""
CONFIG_DIR=false

parse_args() {
  show_help_if_requested usage "$@"

  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  # First non-flag argument is the tool name
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brew)
        [[ $# -lt 2 ]] && { print_error "--brew requires a formula name"; exit 1; }
        BREW_FORMULA="$2"
        shift 2
        ;;
      --cask)
        [[ $# -lt 2 ]] && { print_error "--cask requires a cask name"; exit 1; }
        BREW_CASK="$2"
        shift 2
        ;;
      --config-dir)
        CONFIG_DIR=true
        shift
        ;;
      --no-color)
        shift
        ;;
      -*)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        if [[ -z "$TOOL_NAME" ]]; then
          TOOL_NAME="$1"
        else
          print_error "Unexpected argument: $1"
          usage
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$TOOL_NAME" ]]; then
    print_error "Tool name is required"
    usage
    exit 1
  fi
}

main() {
  parse_args "$@"

  local stow_dir="$DOTFILES/config/$TOOL_NAME"

  # Check if package already exists
  if [[ -d "$stow_dir" ]]; then
    print_error "Stow package '$TOOL_NAME' already exists at $stow_dir"
    exit 1
  fi

  print_header "New Tool: $TOOL_NAME"

  # Create stow directory
  if $CONFIG_DIR; then
    mkdir -p "$stow_dir/.config/$TOOL_NAME"
    print_success "Created config/$TOOL_NAME/.config/$TOOL_NAME/"
  else
    mkdir -p "$stow_dir"
    print_success "Created config/$TOOL_NAME/"
  fi

  # Add to Brewfile
  if [[ -n "$BREW_FORMULA" ]]; then
    local brewfile="$DOTFILES/brew/Brewfile.cli"
    if grep -q "\"$BREW_FORMULA\"" "$brewfile" 2>/dev/null; then
      print_warning "$BREW_FORMULA already in Brewfile.cli"
    else
      echo "brew \"$BREW_FORMULA\"" >> "$brewfile"
      print_success "Added brew \"$BREW_FORMULA\" to Brewfile.cli"
    fi
  fi

  if [[ -n "$BREW_CASK" ]]; then
    local brewfile="$DOTFILES/brew/Brewfile.apps"
    if grep -q "\"$BREW_CASK\"" "$brewfile" 2>/dev/null; then
      print_warning "$BREW_CASK already in Brewfile.apps"
    else
      echo "cask \"$BREW_CASK\"" >> "$brewfile"
      print_success "Added cask \"$BREW_CASK\" to Brewfile.apps"
    fi
  fi

  # Print next steps
  printf '\n'
  print_section "Next steps"
  local step=1

  if $CONFIG_DIR; then
    print_indent "$step. Add config files to config/$TOOL_NAME/.config/$TOOL_NAME/"
  else
    print_indent "$step. Add config files to config/$TOOL_NAME/"
  fi
  step=$((step + 1))

  if [[ -n "$BREW_FORMULA" ]]; then
    print_indent "$step. Install: brew install $BREW_FORMULA"
    step=$((step + 1))
  fi

  if [[ -n "$BREW_CASK" ]]; then
    print_indent "$step. Install: brew install --cask $BREW_CASK"
    step=$((step + 1))
  fi

  print_indent "$step. Stow: make stow"
  step=$((step + 1))
  print_indent "$step. Verify: make doctor"
}

main "$@"
