#!/usr/bin/env bash
# Sync manually installed packages to Brewfiles
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_BREWFILE="$(mktemp "${TMPDIR:-/tmp}/brewfile-current.XXXXXX")"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"
source "$SCRIPT_DIR/../lib/env.sh"
source "$SCRIPT_DIR/../lib/brew.sh"
dotfiles_load_env "$DOTFILES"
trap 'rm -f "$TEMP_BREWFILE"' EXIT
DRY_RUN=false
AUTO=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run] [--auto]

Sync manually installed Homebrew packages into tracked Brewfiles.

Options:
  --auto     Non-interactive: route formulae and taps to Brewfile.cli.
             Casks and VS Code extensions are deliberately skipped for review.
  --dry-run  Show what would be added without modifying Brewfiles.
EOF
}

show_help_if_requested usage "$@"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color|--quiet) shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --auto) AUTO=true; shift ;;
    *) print_error "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

require_cmd "brew" "Install Homebrew first: https://brew.sh" || exit 1

print_header "Syncing Homebrew packages to Brewfiles"
print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
print_status_row "Tracked Brewfiles" info "$(brew_profile_summary)"

# Dump current system state
brew bundle dump --file="$TEMP_BREWFILE" --force

# Read existing Brewfiles into arrays
declare -a DECLARED_KEYS=()

# Parse the explicitly selected exception Brewfiles.
while IFS= read -r brewfile; do
  while IFS= read -r line; do
    if [[ "$line" =~ ^(brew|cask|tap|mas)\ \"([^\"]+)\" ]]; then
      if key=$(brew_entry_key_from_line "$line"); then
        DECLARED_KEYS+=("$key")
      fi
    fi
  done < "$brewfile"
done < <(brewfile_paths "$DOTFILES")

# Find new packages (in current dump but not in any Brewfile)
declare -a NEW_PACKAGES=()
while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue

  # Compare normalized keys so comments/options/tap-qualified names don't
  # appear as false positives.
  if ! key=$(brew_entry_key_from_line "$line"); then
    continue
  fi

  if [[ ! " ${DECLARED_KEYS[*]} " =~ [[:space:]]${key}[[:space:]] ]]; then
    NEW_PACKAGES+=("$line")
  fi
done < "$TEMP_BREWFILE"

# Clean up temp file (also handled by EXIT trap)
rm -f "$TEMP_BREWFILE"

# If no new packages, exit
if [[ ${#NEW_PACKAGES[@]} -eq 0 ]]; then
  print_success "All packages are already in Brewfiles"
  exit 0
fi

# Display new packages and prompt for categorization
print_warning "Found ${#NEW_PACKAGES[@]} new package(s)"
printf '\n'

if $DRY_RUN; then
  print_warning "DRY RUN: no Brewfiles will be modified"
  for pkg in "${NEW_PACKAGES[@]}"; do
    printf "  "
    print_dim "$pkg"
  done
  exit 0
fi

# Append a package line to a Brewfile if not already present.
append_if_missing() {
  local line="$1"
  local file="$2"
  if grep -qF "$line" "$file" 2>/dev/null; then
    print_warning "Already in $(basename "$file"), skipping"
  else
    printf '%s\n' "$line" >> "$file"
    print_success "Added to $(basename "$file")"
  fi
}

# Only generic formulae and taps can be safely routed automatically. A cask
# needs an explicit capability decision; VS Code extensions belong in Nix.
auto_route() {
  local line="$1"
  case "$line" in
    brew\ *|tap\ *)    printf '%s\n' "$DOTFILES/brew/Brewfile.cli" ;;
    *)                 return 1 ;;
  esac
}

for pkg in "${NEW_PACKAGES[@]}"; do
  print_info "Package: $pkg"

  if $AUTO; then
    if dest=$(auto_route "$pkg"); then
      append_if_missing "$pkg" "$dest"
    else
      print_warning "Cannot auto-route, skipped"
    fi
    printf '\n'
    continue
  fi

  case "$pkg" in
    brew\ *|tap\ *)
      read -rp "Add this Homebrew exception to Brewfile.cli? [y/N] " choice
      case "$choice" in
        y|Y|yes|YES) append_if_missing "$pkg" "$DOTFILES/brew/Brewfile.cli" ;;
        *) print_dim "Skipped" ;;
      esac
      ;;
    cask\ *|mas\ *)
      print_dim "Skipped: assess Nix first, then add a named specialist Brewfile if needed."
      ;;
    vscode\ *)
      print_dim "Skipped: add the extension ID to nix/config/vscode/extensions.txt instead."
      ;;
    *) print_dim "Skipped" ;;
  esac
  printf '\n'
done

print_success "Brew sync complete"
printf '\n'
print_section "Remember to:"
print_indent "1. Review changes: git diff brew/"
print_indent "2. Commit changes: git add brew/ && git commit -m 'chore: sync brew packages'"
