#!/usr/bin/env bash
# Migrate ~/Developer/repositories to categorized structure.
# Supports:
#   --dry-run   Preview the planned migration
#   --complete  Complete migration for remaining repos interactively
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

SOURCE_DIR="$HOME/Developer/repositories"
TARGET_DIR="$HOME/Developer"
DRY_RUN=false
COMPLETE_MODE=false

usage() {
  cat << EOF
Usage: $0 [--dry-run] [--complete]

Modes:
  --dry-run   Preview standard migration plan without moving repos.
  --complete  Complete migration for remaining repos in legacy layout.
EOF
}

to_kebab_case() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

move_repo() {
  local source="$1"
  local target="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  Would move: $source → $target"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  mv "$source" "$target"
  echo -e "  ${GREEN}✓${NC} Moved: $(basename "$source") → $target"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --complete)
        COMPLETE_MODE=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --no-color)
        shift
        ;;
      *)
        echo -e "${RED}Unknown argument: $1${NC}"
        usage
        exit 1
        ;;
    esac
  done

  if [[ "$DRY_RUN" == "true" && "$COMPLETE_MODE" == "true" ]]; then
    echo -e "${RED}Cannot combine --dry-run with --complete${NC}"
    usage
    exit 1
  fi
}

ensure_legacy_source_exists() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo -e "${RED}Error: Source directory not found: $SOURCE_DIR${NC}"
    exit 1
  fi
}

create_standard_backup() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return
  fi

  BACKUP_DIR="$HOME/Developer-backup-$(date +%Y%m%d-%H%M%S)"
  echo -e "${BLUE}Creating backup...${NC}"
  cp -r "$HOME/Developer" "$BACKUP_DIR"
  echo -e "${GREEN}✓${NC} Backup created: $BACKUP_DIR"
  echo ""
}

prepare_target_layout() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return
  fi

  mkdir -p "$TARGET_DIR/personal/projects"
  mkdir -p "$TARGET_DIR/personal/experiments"
  mkdir -p "$TARGET_DIR/personal/learning"
  mkdir -p "$TARGET_DIR/work/projects"
  mkdir -p "$TARGET_DIR/work/clients/celebratix"
  mkdir -p "$TARGET_DIR/archive/codam"
}

cleanup_legacy_tree() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return
  fi

  echo -e "${BLUE}Cleaning up empty directories...${NC}"
  find "$SOURCE_DIR" -type d -empty -delete 2>/dev/null || true
  if [[ -d "$SOURCE_DIR" ]] && [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
    rmdir "$SOURCE_DIR"
    echo -e "${GREEN}✓${NC} Removed empty $SOURCE_DIR"
  elif [[ -d "$SOURCE_DIR" ]]; then
    echo -e "${YELLOW}⚠${NC} $SOURCE_DIR still contains files:"
    ls -la "$SOURCE_DIR"
  fi
  echo ""
}

print_standard_summary() {
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
    echo "  5. If all good: make complete-migration"
    echo ""
    echo "Backup location: $BACKUP_DIR"
  fi
}

run_standard_migration() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}DRY RUN MODE - No files will be moved${NC}"
    echo ""
  fi

  if [[ ! -d "$SOURCE_DIR" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${GREEN}✓${NC} No legacy source found at $SOURCE_DIR"
      echo "Migration preview not needed on this machine."
      exit 0
    fi
    ensure_legacy_source_exists
  fi

  echo -e "${BLUE}Developer Directory Migration${NC}"
  echo "=============================="
  echo ""

  create_standard_backup
  prepare_target_layout

  echo -e "${BLUE}Migration Plan:${NC}"
  echo ""

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

  cleanup_legacy_tree
  print_standard_summary
}

move_repo_safely_with_checks() {
  local source="$1"
  local target="$2"
  local repo_name
  repo_name="$(basename "$source")"

  echo -e "${BLUE}Moving:${NC} $repo_name"
  echo "  From: $source"
  echo "  To: $target"

  if [[ -d "$target" ]]; then
    echo -e "${YELLOW}  ⚠ Target already exists - skipping (possible duplicate)${NC}"
    return
  fi

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

  mkdir -p "$(dirname "$target")"
  mv "$source" "$target"

  cd "$target"
  if git status &>/dev/null; then
    echo -e "${GREEN}  ✓ Moved successfully${NC}"
  else
    echo -e "${RED}  ✗ Git verification failed!${NC}"
    return 1
  fi

  echo ""
}

run_completion_migration() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo -e "${GREEN}✓${NC} No old repositories directory found - migration already complete!"
    exit 0
  fi

  echo -e "${BLUE}==>${NC} Completing Developer Directory Migration"
  echo ""

  repo_count=$(find "$SOURCE_DIR" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  if [[ "$repo_count" -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} No repos found in old location"
    echo "Cleaning up empty directories..."
    rm -rf "$SOURCE_DIR"
    echo -e "${GREEN}✓${NC} Migration complete!"
    exit 0
  fi

  echo -e "${YELLOW}Found $repo_count unmigrated repo(s)${NC}"
  echo ""

  if [[ -d "$SOURCE_DIR/Projects" ]]; then
    echo -e "${BLUE}Processing Projects folder...${NC}"
    for repo in "$SOURCE_DIR/Projects"/*; do
      if [[ -d "$repo/.git" ]]; then
        repo_name="$(basename "$repo")"
        kebab_name="$(to_kebab_case "$repo_name")"
        target="$TARGET_DIR/personal/projects/$kebab_name"
        move_repo_safely_with_checks "$repo" "$target" || true
      fi
    done
  fi

  if [[ -d "$SOURCE_DIR/effect" ]]; then
    echo -e "${BLUE}Processing effect folder...${NC}"
    for repo in "$SOURCE_DIR/effect"/*; do
      if [[ -d "$repo/.git" ]]; then
        repo_name="$(basename "$repo")"
        kebab_name="$(to_kebab_case "$repo_name")"
        target="$TARGET_DIR/personal/learning/$kebab_name"
        move_repo_safely_with_checks "$repo" "$target" || true
      fi
    done
  fi

  if [[ -d "$SOURCE_DIR/Celebratix" ]]; then
    echo -e "${BLUE}Processing Celebratix folder...${NC}"
    for repo in "$SOURCE_DIR/Celebratix"/*; do
      if [[ -d "$repo/.git" ]]; then
        repo_name="$(basename "$repo")"
        kebab_name="$(to_kebab_case "$repo_name")"
        target="$TARGET_DIR/work/clients/celebratix/$kebab_name"
        move_repo_safely_with_checks "$repo" "$target" || true
      fi
    done
  fi

  for repo in "$SOURCE_DIR"/*; do
    if [[ -d "$repo/.git" ]]; then
      repo_name="$(basename "$repo")"
      echo -e "${YELLOW}Found unmapped repo: $repo_name${NC}"
      echo "Where should this go?"
      echo "  1) personal/projects"
      echo "  2) personal/experiments"
      echo "  3) personal/learning"
      echo "  4) work/projects"
      echo "  5) archive"
      read -rp "Choice [1-5]: " choice

      kebab_name="$(to_kebab_case "$repo_name")"
      case "$choice" in
        1) target="$TARGET_DIR/personal/projects/$kebab_name" ;;
        2) target="$TARGET_DIR/personal/experiments/$kebab_name" ;;
        3) target="$TARGET_DIR/personal/learning/$kebab_name" ;;
        4) target="$TARGET_DIR/work/projects/$kebab_name" ;;
        5) target="$TARGET_DIR/archive/$kebab_name" ;;
        *) echo "Skipped"; continue ;;
      esac

      move_repo_safely_with_checks "$repo" "$target" || true
    fi
  done

  echo -e "${BLUE}Cleaning up empty directories...${NC}"
  find "$SOURCE_DIR" -type d -empty -delete 2>/dev/null || true
  if [[ -d "$SOURCE_DIR" ]] && [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
    rmdir "$SOURCE_DIR"
    echo -e "${GREEN}✓${NC} Removed empty repositories directory"
  elif [[ -d "$SOURCE_DIR" ]]; then
    echo -e "${YELLOW}⚠${NC} repositories directory still has content:"
    ls -la "$SOURCE_DIR"
  fi

  echo ""
  echo -e "${GREEN}✓${NC} Migration completion finished!"
  echo ""
  echo "Verify with:"
  echo "  find ~/Developer -name '.git' -type d | wc -l"
  echo "  proj"
}

main() {
  parse_args "$@"
  if [[ "$COMPLETE_MODE" == "true" ]]; then
    run_completion_migration
  else
    run_standard_migration
  fi
}

main "$@"
