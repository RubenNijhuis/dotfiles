#!/usr/bin/env bash
# Validate all git repositories are safe to migrate
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Find all git repositories
# Default to new organized structure, but accept custom path as argument
REPOS_DIR="${1:-$HOME/Developer}"

if [[ ! -d "$REPOS_DIR" ]]; then
  echo -e "${RED}Error: Directory not found: $REPOS_DIR${NC}"
  exit 1
fi

echo -e "${BLUE}Repository Safety Report${NC}"
echo "========================"
echo ""

# Counters
safe_count=0
uncommitted_count=0
unpushed_count=0
stashed_count=0

# Arrays to track issues
declare -a uncommitted_repos
declare -a unpushed_repos
declare -a stashed_repos

# Find all git repos recursively
while IFS= read -r -d '' git_dir; do
  repo_dir="$(dirname "$git_dir")"
  repo_name="$(basename "$repo_dir")"

  cd "$repo_dir"

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    uncommitted_repos+=("$repo_name: $(git diff --name-only | wc -l | xargs) files")
    ((uncommitted_count++))
    continue
  fi

  # Check for unpushed commits
  if git rev-parse @{u} &>/dev/null; then
    commits_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    if [[ "$commits_ahead" -gt 0 ]]; then
      unpushed_repos+=("$repo_name: $commits_ahead commits")
      ((unpushed_count++))
      continue
    fi
  fi

  # Check for stashes
  stash_count=$(git stash list | wc -l | xargs)
  if [[ "$stash_count" -gt 0 ]]; then
    stashed_repos+=("$repo_name: $stash_count stashes")
    ((stashed_count++))
    continue
  fi

  ((safe_count++))
done < <(find "$REPOS_DIR" -name ".git" -type d -print0)

total_count=$((safe_count + uncommitted_count + unpushed_count + stashed_count))

# Summary
if [[ $uncommitted_count -eq 0 && $unpushed_count -eq 0 && $stashed_count -eq 0 ]]; then
  echo -e "${GREEN}✓ All $safe_count repos are safe to migrate${NC}"
  echo ""
  exit 0
else
  echo -e "${GREEN}✓ Safe: $safe_count repos${NC}"
  echo -e "${YELLOW}⚠ Needs attention: $((uncommitted_count + unpushed_count + stashed_count)) repos${NC}"
  echo ""
fi

# Details
if [[ $uncommitted_count -gt 0 ]]; then
  echo -e "${YELLOW}UNCOMMITTED CHANGES:${NC}"
  for repo in "${uncommitted_repos[@]}"; do
    echo "  - $repo"
  done
  echo ""
fi

if [[ $unpushed_count -gt 0 ]]; then
  echo -e "${YELLOW}UNPUSHED COMMITS:${NC}"
  for repo in "${unpushed_repos[@]}"; do
    echo "  - $repo"
  done
  echo ""
fi

if [[ $stashed_count -gt 0 ]]; then
  echo -e "${YELLOW}STASHED CHANGES:${NC}"
  for repo in "${stashed_repos[@]}"; do
    echo "  - $repo"
  done
  echo ""
fi

# Action required
echo -e "${RED}ACTION REQUIRED:${NC}"
echo "1. Commit or stash uncommitted changes"
echo "2. Push unpushed commits"
echo "3. Run validation again: make validate-repos"
echo ""

exit 1
