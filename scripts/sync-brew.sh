#!/usr/bin/env bash
# Sync manually installed packages to Brewfiles
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE_FILE="$HOME/.config/dotfiles-profile"
TEMP_BREWFILE="/tmp/brewfile-current.$$"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Read current profile
if [[ ! -f "$PROFILE_FILE" ]]; then
  echo "No profile found. Run install.sh first."
  exit 1
fi
PROFILE="$(cat "$PROFILE_FILE")"

echo -e "${BLUE}==>${NC} Syncing Homebrew packages to Brewfiles"
echo "Profile: $PROFILE"
echo ""

# Dump current system state
brew bundle dump --file="$TEMP_BREWFILE" --force

# Read existing Brewfiles into arrays
declare -a COMMON_PACKAGES
declare -a PROFILE_PACKAGES

# Parse Brewfile.common
while IFS= read -r line; do
  if [[ "$line" =~ ^(brew|cask|tap|vscode|mas)\ \"([^\"]+)\" ]]; then
    COMMON_PACKAGES+=("$line")
  fi
done < "$DOTFILES/brew/Brewfile.common"

# Parse profile-specific Brewfile
while IFS= read -r line; do
  if [[ "$line" =~ ^(brew|cask|tap|vscode|mas)\ \"([^\"]+)\" ]]; then
    PROFILE_PACKAGES+=("$line")
  fi
done < "$DOTFILES/brew/Brewfile.$PROFILE"

# Find new packages (in current dump but not in any Brewfile)
declare -a NEW_PACKAGES
while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue

  # Check if package exists in common or profile Brewfile
  found=false
  for pkg in "${COMMON_PACKAGES[@]}" "${PROFILE_PACKAGES[@]}"; do
    if [[ "$line" == "$pkg" ]]; then
      found=true
      break
    fi
  done

  if [[ "$found" == "false" ]]; then
    NEW_PACKAGES+=("$line")
  fi
done < "$TEMP_BREWFILE"

# Clean up temp file
rm "$TEMP_BREWFILE"

# If no new packages, exit
if [[ ${#NEW_PACKAGES[@]} -eq 0 ]]; then
  echo -e "${GREEN}✓${NC} All packages are already in Brewfiles"
  exit 0
fi

# Display new packages and prompt for categorization
echo -e "${YELLOW}Found ${#NEW_PACKAGES[@]} new package(s):${NC}"
echo ""

for pkg in "${NEW_PACKAGES[@]}"; do
  echo -e "${BLUE}Package:${NC} $pkg"
  echo "Add to:"
  echo "  1) Brewfile.common (shared across all profiles)"
  echo "  2) Brewfile.$PROFILE (current profile only)"
  echo "  3) Skip (don't add to any Brewfile)"
  read -rp "Choice [1/2/3]: " choice

  case "$choice" in
    1)
      echo "$pkg" >> "$DOTFILES/brew/Brewfile.common"
      echo -e "${GREEN}✓${NC} Added to Brewfile.common"
      ;;
    2)
      echo "$pkg" >> "$DOTFILES/brew/Brewfile.$PROFILE"
      echo -e "${GREEN}✓${NC} Added to Brewfile.$PROFILE"
      ;;
    *)
      echo "Skipped"
      ;;
  esac
  echo ""
done

echo -e "${GREEN}✓${NC} Brew sync complete"
echo ""
echo "Remember to:"
echo "  1. Review changes: git diff brew/"
echo "  2. Commit changes: git add brew/ && git commit -m 'chore: sync brew packages'"
