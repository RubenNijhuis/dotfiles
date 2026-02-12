#!/usr/bin/env bash
# Complete the Developer directory migration
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
OLD_BASE="$HOME/Developer/repositories"
NEW_BASE="$HOME/Developer"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==>${NC} Completing Developer Directory Migration"
echo ""

# Find all remaining git repos in old location
if [[ ! -d "$OLD_BASE" ]]; then
    echo -e "${GREEN}✓${NC} No old repositories directory found - migration already complete!"
    exit 0
fi

# Count repos
REPO_COUNT=$(find "$OLD_BASE" -name ".git" -type d 2>/dev/null | wc -l | xargs)

if [[ "$REPO_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} No repos found in old location"
    echo "Cleaning up empty directories..."
    rm -rf "$OLD_BASE"
    echo -e "${GREEN}✓${NC} Migration complete!"
    exit 0
fi

echo -e "${YELLOW}Found $REPO_COUNT unmigrated repo(s)${NC}"
echo ""

# Helper function: convert to kebab-case
to_kebab_case() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9-]/-/g'
}

# Move a repo safely
move_repo() {
    local source="$1"
    local target="$2"
    local repo_name=$(basename "$source")

    echo -e "${BLUE}Moving:${NC} $repo_name"
    echo "  From: $source"
    echo "  To: $target"

    # Check if target already exists
    if [[ -d "$target" ]]; then
        echo -e "${YELLOW}  ⚠ Target already exists - skipping (possible duplicate)${NC}"
        return
    fi

    # Check git status
    cd "$source"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${RED}  ✗ Has uncommitted changes - commit first!${NC}"
        return 1
    fi

    if git log --branches --not --remotes 2>/dev/null | head -n 1 | grep -q .; then
        echo -e "${YELLOW}  ⚠ Has unpushed commits - consider pushing first${NC}"
        read -rp "  Continue anyway? [y/N] " confirm
        if [[ ! "${confirm:-N}" =~ ^[Yy] ]]; then
            return 1
        fi
    fi

    # Move the repo
    mkdir -p "$(dirname "$target")"
    mv "$source" "$target"

    # Verify git still works
    cd "$target"
    if git status &>/dev/null; then
        echo -e "${GREEN}  ✓ Moved successfully${NC}"
    else
        echo -e "${RED}  ✗ Git verification failed!${NC}"
        return 1
    fi

    echo ""
}

# Process Projects folder
if [[ -d "$OLD_BASE/Projects" ]]; then
    echo -e "${BLUE}Processing Projects folder...${NC}"
    for repo in "$OLD_BASE/Projects"/*; do
        if [[ -d "$repo/.git" ]]; then
            repo_name=$(basename "$repo")
            kebab_name=$(to_kebab_case "$repo_name")
            target="$NEW_BASE/personal/projects/$kebab_name"
            move_repo "$repo" "$target" || true
        fi
    done
fi

# Process effect folder (learning projects)
if [[ -d "$OLD_BASE/effect" ]]; then
    echo -e "${BLUE}Processing effect folder...${NC}"
    for repo in "$OLD_BASE/effect"/*; do
        if [[ -d "$repo/.git" ]]; then
            repo_name=$(basename "$repo")
            kebab_name=$(to_kebab_case "$repo_name")
            target="$NEW_BASE/personal/learning/$kebab_name"
            move_repo "$repo" "$target" || true
        fi
    done
fi

# Process Celebratix folder (work clients)
if [[ -d "$OLD_BASE/Celebratix" ]]; then
    echo -e "${BLUE}Processing Celebratix folder...${NC}"
    for repo in "$OLD_BASE/Celebratix"/*; do
        if [[ -d "$repo/.git" ]]; then
            repo_name=$(basename "$repo")
            kebab_name=$(to_kebab_case "$repo_name")
            target="$NEW_BASE/work/clients/celebratix/$kebab_name"
            move_repo "$repo" "$target" || true
        fi
    done
fi

# Handle any other remaining repos at root level
for repo in "$OLD_BASE"/*; do
    if [[ -d "$repo/.git" ]]; then
        repo_name=$(basename "$repo")
        echo -e "${YELLOW}Found unmapped repo: $repo_name${NC}"
        echo "Where should this go?"
        echo "  1) personal/projects"
        echo "  2) personal/experiments"
        echo "  3) personal/learning"
        echo "  4) work/projects"
        echo "  5) archive"
        read -rp "Choice [1-5]: " choice

        kebab_name=$(to_kebab_case "$repo_name")

        case "$choice" in
            1) target="$NEW_BASE/personal/projects/$kebab_name" ;;
            2) target="$NEW_BASE/personal/experiments/$kebab_name" ;;
            3) target="$NEW_BASE/personal/learning/$kebab_name" ;;
            4) target="$NEW_BASE/work/projects/$kebab_name" ;;
            5) target="$NEW_BASE/archive/$kebab_name" ;;
            *) echo "Skipped"; continue ;;
        esac

        move_repo "$repo" "$target" || true
    fi
done

# Clean up empty directories
echo -e "${BLUE}Cleaning up empty directories...${NC}"
find "$OLD_BASE" -type d -empty -delete 2>/dev/null || true

# Remove repositories folder if empty
if [[ -d "$OLD_BASE" ]]; then
    if [[ -z "$(ls -A "$OLD_BASE")" ]]; then
        rmdir "$OLD_BASE"
        echo -e "${GREEN}✓${NC} Removed empty repositories directory"
    else
        echo -e "${YELLOW}⚠${NC} repositories directory still has content:"
        ls -la "$OLD_BASE"
    fi
fi

echo ""
echo -e "${GREEN}✓${NC} Migration completion script finished!"
echo ""
echo "Verify with:"
echo "  find ~/Developer -name '.git' -type d | wc -l  # Should be 44"
echo "  proj  # Test fuzzy finder"
