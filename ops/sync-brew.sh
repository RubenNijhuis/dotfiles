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

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Sync manually installed Homebrew packages into tracked Brewfiles.
EOF
}

parse_standard_args usage --accept-dry-run "$@"

require_cmd "brew" "Install Homebrew first: https://brew.sh" || exit 1

print_header "Syncing Homebrew packages to Brewfiles"
print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
print_status_row "Tracked Brewfiles" info "$(brew_profile_summary)"

# Dump current system state
brew bundle dump --file="$TEMP_BREWFILE" --force

# Read existing Brewfiles into arrays
declare -a DECLARED_PACKAGES=()
declare -a DECLARED_KEYS=()

# Parse all Brewfiles (cli, apps, vscode)
while IFS= read -r brewfile; do
  while IFS= read -r line; do
    if [[ "$line" =~ ^(brew|cask|tap|vscode|mas)\ \"([^\"]+)\" ]]; then
      DECLARED_PACKAGES+=("$line")
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

for pkg in "${NEW_PACKAGES[@]}"; do
  print_info "Package: $pkg"
  print_subsection "Add to:"
  print_indent "1) Brewfile.cli (CLI tools)"
  print_indent "2) Brewfile.apps (GUI apps)"
  print_indent "3) Brewfile.vscode (VS Code extensions)"
  print_indent "4) Skip (don't add to any Brewfile)"
  read -rp "Choice [1/2/3/4]: " choice

  case "$choice" in
    1) append_if_missing "$pkg" "$DOTFILES/brew/Brewfile.cli" ;;
    2) append_if_missing "$pkg" "$DOTFILES/brew/Brewfile.apps" ;;
    3) append_if_missing "$pkg" "$DOTFILES/brew/Brewfile.vscode" ;;
    *) print_dim "Skipped" ;;
  esac
  printf '\n'
done

print_success "Brew sync complete"
printf '\n'
print_section "Remember to:"
print_indent "1. Review changes: git diff brew/"
print_indent "2. Commit changes: git add brew/ && git commit -m 'chore: sync brew packages'"
