#!/usr/bin/env bash
# Sync manually installed packages to Brewfiles
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROFILE_FILE="$HOME/.config/dotfiles-profile"
TEMP_BREWFILE="/tmp/brewfile-current.$$"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run]

Sync manually installed Homebrew packages into tracked Brewfiles.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --dry-run)
        DRY_RUN=true
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

parse_args "$@"

# Read current profile
if [[ ! -f "$PROFILE_FILE" ]]; then
  print_error "No profile found. Run install.sh first."
  exit 1
fi
PROFILE="$(cat "$PROFILE_FILE")"

require_cmd "brew" "Install Homebrew first: https://brew.sh" >/dev/null || {
  print_error "Homebrew is required"
  exit 1
}

print_header "Syncing Homebrew packages to Brewfiles"
print_key_value "Profile" "$PROFILE"
echo

# Dump current system state
brew bundle dump --file="$TEMP_BREWFILE" --force

# Read existing Brewfiles into arrays
declare -a COMMON_PACKAGES=()
declare -a PROFILE_PACKAGES=()
declare -a DECLARED_KEYS=()

entry_key_from_line() {
  local line="$1"
  local kind name normalized

  if [[ "$line" =~ ^(brew|cask|tap|vscode|mas)[[:space:]]+\"([^\"]+)\" ]]; then
    kind="${BASH_REMATCH[1]}"
    name="${BASH_REMATCH[2]}"

    case "$kind" in
      tap) normalized="$name" ;;
      *) normalized="${name##*/}" ;;
    esac

    printf '%s:%s\n' "$kind" "$normalized"
    return 0
  fi

  return 1
}

array_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

# Parse Brewfile.common
while IFS= read -r line; do
  if [[ "$line" =~ ^(brew|cask|tap|vscode|mas)\ \"([^\"]+)\" ]]; then
    COMMON_PACKAGES+=("$line")
    if key=$(entry_key_from_line "$line"); then
      DECLARED_KEYS+=("$key")
    fi
  fi
done < "$DOTFILES/brew/Brewfile.common"

# Parse profile-specific Brewfile
while IFS= read -r line; do
  if [[ "$line" =~ ^(brew|cask|tap|vscode|mas)\ \"([^\"]+)\" ]]; then
    PROFILE_PACKAGES+=("$line")
    if key=$(entry_key_from_line "$line"); then
      DECLARED_KEYS+=("$key")
    fi
  fi
done < "$DOTFILES/brew/Brewfile.$PROFILE"

# Find new packages (in current dump but not in any Brewfile)
declare -a NEW_PACKAGES=()
while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue

  # Compare normalized keys so comments/options/tap-qualified names don't
  # appear as false positives.
  if ! key=$(entry_key_from_line "$line"); then
    continue
  fi

  if ! array_contains "$key" "${DECLARED_KEYS[@]}"; then
    NEW_PACKAGES+=("$line")
  fi
done < "$TEMP_BREWFILE"

# Clean up temp file
rm "$TEMP_BREWFILE"

# If no new packages, exit
if [[ ${#NEW_PACKAGES[@]} -eq 0 ]]; then
  print_success "All packages are already in Brewfiles"
  exit 0
fi

# Display new packages and prompt for categorization
print_warning "Found ${#NEW_PACKAGES[@]} new package(s)"
echo

if $DRY_RUN; then
  print_warning "DRY RUN: no Brewfiles will be modified"
  for pkg in "${NEW_PACKAGES[@]}"; do
    printf "  "
    print_dim "$pkg"
  done
  exit 0
fi

for pkg in "${NEW_PACKAGES[@]}"; do
  print_info "Package: $pkg"
  echo "Add to:"
  echo "  1) Brewfile.common (shared across all profiles)"
  echo "  2) Brewfile.$PROFILE (current profile only)"
  echo "  3) Skip (don't add to any Brewfile)"
  read -rp "Choice [1/2/3]: " choice

  case "$choice" in
    1)
      echo "$pkg" >> "$DOTFILES/brew/Brewfile.common"
      print_success "Added to Brewfile.common"
      ;;
    2)
      echo "$pkg" >> "$DOTFILES/brew/Brewfile.$PROFILE"
      print_success "Added to Brewfile.$PROFILE"
      ;;
    *)
      print_dim "Skipped"
      ;;
  esac
  echo ""
done

print_success "Brew sync complete"
echo ""
echo "Remember to:"
echo "  1. Review changes: git diff brew/"
echo "  2. Commit changes: git add brew/ && git commit -m 'chore: sync brew packages'"
