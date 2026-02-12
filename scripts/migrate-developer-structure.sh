#!/usr/bin/env bash
# Migrate ~/Developer/repositories to new categorized structure
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SOURCE_DIR="$HOME/Developer/repositories"
TARGET_DIR="$HOME/Developer"
DRY_RUN=false

# Parse arguments
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo -e "${YELLOW}DRY RUN MODE - No files will be moved${NC}"
  echo ""
fi

# Check source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo -e "${RED}Error: Source directory not found: $SOURCE_DIR${NC}"
  exit 1
fi

# Convert to kebab-case
to_kebab_case() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# Move function with dry-run support
move_repo() {
  local source="$1"
  local target="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  Would move: $source → $target"
  else
    mkdir -p "$(dirname "$target")"
    mv "$source" "$target"
    echo -e "  ${GREEN}✓${NC} Moved: $(basename "$source") → $target"
  fi
}

echo -e "${BLUE}Developer Directory Migration${NC}"
echo "=============================="
echo ""

# Create backup if not dry run
if [[ "$DRY_RUN" == "false" ]]; then
  BACKUP_DIR="$HOME/Developer-backup-$(date +%Y%m%d-%H%M%S)"
  echo -e "${BLUE}Creating backup...${NC}"
  cp -r "$HOME/Developer" "$BACKUP_DIR"
  echo -e "${GREEN}✓${NC} Backup created: $BACKUP_DIR"
  echo ""
fi

# Create target directories
if [[ "$DRY_RUN" == "false" ]]; then
  mkdir -p "$TARGET_DIR/personal/projects"
  mkdir -p "$TARGET_DIR/personal/experiments"
  mkdir -p "$TARGET_DIR/personal/learning"
  mkdir -p "$TARGET_DIR/work/projects"
  mkdir -p "$TARGET_DIR/work/clients/celebratix"
  mkdir -p "$TARGET_DIR/archive/codam"
fi

# Migration plan
echo -e "${BLUE}Migration Plan:${NC}"
echo ""

# Work - Celebratix
echo -e "${YELLOW}Work - Celebratix (4 repos):${NC}"
if [[ -d "$SOURCE_DIR/Celebratix" ]]; then
  for repo in "$SOURCE_DIR/Celebratix"/*; do
    if [[ -d "$repo" ]]; then
      repo_name="$(basename "$repo")"
      kebab_name="$(to_kebab_case "$repo_name")"
      target="$TARGET_DIR/work/clients/celebratix/$kebab_name"
      move_repo "$repo" "$target"
    fi
  done
else
  echo "  Celebratix directory not found"
fi
echo ""

# Personal Projects (top-level personal repos)
echo -e "${YELLOW}Personal Projects (11 repos):${NC}"
personal_projects=(
  "Interesting-Websites"
  "Portfolio22"
  "Reusable-Components"
  "SRC-API"
  "node-sdk-server"
  "obsidian-store"
  "rubennijhuis"
  "dotfiles"
  "Advent-Of-Code"
  "Socket-Room-Manager"
  "vockhuis-gl"
)

for proj in "${personal_projects[@]}"; do
  if [[ -d "$SOURCE_DIR/$proj" ]]; then
    kebab_name="$(to_kebab_case "$proj")"
    target="$TARGET_DIR/personal/projects/$kebab_name"
    move_repo "$SOURCE_DIR/$proj" "$target"
  fi
done
echo ""

# Personal Experiments
echo -e "${YELLOW}Personal Experiments (11 repos):${NC}"
if [[ -d "$SOURCE_DIR/Experiments" ]]; then
  for repo in "$SOURCE_DIR/Experiments"/*; do
    if [[ -d "$repo" ]]; then
      repo_name="$(basename "$repo")"
      kebab_name="$(to_kebab_case "$repo_name")"
      target="$TARGET_DIR/personal/experiments/$kebab_name"
      move_repo "$repo" "$target"
    fi
  done
else
  echo "  Experiments directory not found"
fi
echo ""

# Personal Learning
echo -e "${YELLOW}Personal Learning (2 repos):${NC}"
if [[ -d "$SOURCE_DIR/Projects/the-farmer-was-replaced" ]]; then
  kebab_name="$(to_kebab_case "the-farmer-was-replaced")"
  target="$TARGET_DIR/personal/learning/$kebab_name"
  move_repo "$SOURCE_DIR/Projects/the-farmer-was-replaced" "$target"
fi

if [[ -d "$SOURCE_DIR/effect/cheffect" ]]; then
  target="$TARGET_DIR/personal/learning/cheffect"
  move_repo "$SOURCE_DIR/effect/cheffect" "$target"
fi
echo ""

# Archive - Codam
echo -e "${YELLOW}Archive - Codam (17 repos):${NC}"
if [[ -d "$SOURCE_DIR/Codam" ]]; then
  for repo in "$SOURCE_DIR/Codam"/*; do
    if [[ -d "$repo/.git" ]]; then
      repo_name="$(basename "$repo")"
      kebab_name="$(to_kebab_case "$repo_name")"
      target="$TARGET_DIR/archive/codam/$kebab_name"
      move_repo "$repo" "$target"
    fi
  done
else
  echo "  Codam directory not found"
fi
echo ""

# Clean up empty directories
if [[ "$DRY_RUN" == "false" ]]; then
  echo -e "${BLUE}Cleaning up empty directories...${NC}"
  find "$SOURCE_DIR" -type d -empty -delete 2>/dev/null || true
  if [[ -d "$SOURCE_DIR" ]]; then
    # Check if repositories directory is now empty
    if [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
      rmdir "$SOURCE_DIR"
      echo -e "${GREEN}✓${NC} Removed empty $SOURCE_DIR"
    else
      echo -e "${YELLOW}⚠${NC} $SOURCE_DIR still contains files:"
      ls -la "$SOURCE_DIR"
    fi
  fi
  echo ""
fi

# Verification
echo -e "${BLUE}Verification:${NC}"
total_repos=$(find "$TARGET_DIR" -name ".git" -type d 2>/dev/null | wc -l | xargs)
echo "Total repositories in new structure: $total_repos"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}DRY RUN COMPLETE${NC}"
  echo "Run without --dry-run to execute migration"
else
  echo -e "${GREEN}✓ Migration complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Verify: find ~/Developer -name .git -type d | wc -l"
  echo "  2. Test: proj (should list all projects)"
  echo "  3. Test: cd ~/Developer/personal/projects/portfolio22 && git fetch"
  echo "  4. Test: cd ~/Developer/work/clients/celebratix/celebratix-backend && git fetch"
  echo "  5. If all good: rm -rf ~/Developer/repositories"
  echo ""
  echo "Backup location: $BACKUP_DIR"
fi
