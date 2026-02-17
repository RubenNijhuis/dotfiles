#!/usr/bin/env bash
# Validate all git repositories are safe to migrate
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [path]

Validate git repositories for uncommitted, unpushed, or stashed work.
Defaults to: \$HOME/Developer
EOF
}

parse_args() {
  REPOS_DIR="$HOME/Developer"

  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        if [[ "${1#-}" != "$1" ]]; then
          print_error "Unknown argument: $1"
          usage
          exit 1
        fi
        REPOS_DIR="$1"
        shift
        ;;
    esac
  done
}

parse_args "$@"

if [[ ! -d "$REPOS_DIR" ]]; then
  print_error "Directory not found: $REPOS_DIR"
  exit 1
fi

require_cmd "git" "Install Git first: brew install git" >/dev/null || {
  print_error "Git is required"
  exit 1
}

print_header "Repository Safety Report"

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

# shellcheck disable=SC2034  # total_count kept for future summary improvements
total_count=$((safe_count + uncommitted_count + unpushed_count + stashed_count))

# Summary
if [[ $uncommitted_count -eq 0 && $unpushed_count -eq 0 && $stashed_count -eq 0 ]]; then
  print_success "All $safe_count repos are safe to migrate"
  echo
  exit 0
else
  print_success "Safe: $safe_count repos"
  print_warning "Needs attention: $((uncommitted_count + unpushed_count + stashed_count)) repos"
  echo
fi

# Details
if [[ $uncommitted_count -gt 0 ]]; then
  print_section "UNCOMMITTED CHANGES:"
  for repo in "${uncommitted_repos[@]}"; do
    echo "  - $repo"
  done
  echo ""
fi

if [[ $unpushed_count -gt 0 ]]; then
  print_section "UNPUSHED COMMITS:"
  for repo in "${unpushed_repos[@]}"; do
    echo "  - $repo"
  done
  echo ""
fi

if [[ $stashed_count -gt 0 ]]; then
  print_section "STASHED CHANGES:"
  for repo in "${stashed_repos[@]}"; do
    echo "  - $repo"
  done
  echo ""
fi

# Action required
print_error "ACTION REQUIRED:"
echo "1. Commit or stash uncommitted changes"
echo "2. Push unpushed commits"
echo "3. Run validation again: make validate-repos"
echo ""

exit 1
