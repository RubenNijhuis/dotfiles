#!/usr/bin/env bash
# Update all git repositories in Developer directory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/env.sh"
dotfiles_load_env "$(cd "$SCRIPT_DIR/.." && pwd)"

UPDATED=0 FAILED=0 SKIPPED=0
DRY_RUN=false
JOBS=15
FETCH_TIMEOUT=30
DEVELOPER_ROOT="$DOTFILES_DEVELOPER_ROOT"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run] [--jobs N] [--timeout N] [path]

Update all git repositories under the provided path (default: \$DOTFILES_DEVELOPER_ROOT).

Options:
  --jobs N, -j N     Parallel jobs (default: 15)
  --timeout N, -t N  Fetch timeout in seconds (default: 30)
  --dry-run          Preview without making changes
  --no-color         Disable colored output
EOF
}

REPOS_DIR="$DEVELOPER_ROOT"
show_help_if_requested usage "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color) shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --jobs|-j) JOBS="$2"; shift 2 ;;
    --timeout|-t) FETCH_TIMEOUT="$2"; shift 2 ;;
    -*) print_error "Unknown argument: $1"; usage; exit 1 ;;
    *) REPOS_DIR="$1"; shift ;;
  esac
done

# Check if a .git path is nested inside another repo (submodule)
is_submodule() {
  local check_dir
  check_dir="$(dirname "$(dirname "$1")")"
  while [[ "$check_dir" != "/" && "$check_dir" != "$REPOS_DIR" ]]; do
    [[ -d "$check_dir/.git" || -f "$check_dir/.git" ]] && return 0
    check_dir="$(dirname "$check_dir")"
  done
  return 1
}

update_repo() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$(dirname "$repo_path")")"

  cd "$(dirname "$repo_path")" || exit 1

  # Skip: bare repos, no commits, detached HEAD, rebase/merge in progress, index.lock
  [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]] && exit 2
  git rev-parse HEAD &>/dev/null || exit 2
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  [[ "$branch" == "HEAD" || -z "$branch" ]] && exit 2
  local gd
  gd="$(git rev-parse --git-dir 2>/dev/null)"
  [[ -d "$gd/rebase-merge" || -d "$gd/rebase-apply" || -f "$gd/MERGE_HEAD" || -f "$gd/index.lock" ]] && exit 2

  # Stash uncommitted changes
  local stashed=false
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    $DRY_RUN && { printf "  "; print_info "$repo_name: would stash and update"; exit 0; }
    git stash push --include-untracked -m "update-repos: auto-stash" &>/dev/null && stashed=true || exit 2
  fi

  # Fetch with timeout
  local fetch_cmd="git fetch --all --prune"
  if command -v gtimeout &>/dev/null; then fetch_cmd="gtimeout $FETCH_TIMEOUT $fetch_cmd"
  elif command -v timeout &>/dev/null; then fetch_cmd="timeout $FETCH_TIMEOUT $fetch_cmd"; fi
  if ! eval "$fetch_cmd" &>/dev/null; then
    $stashed && git stash pop &>/dev/null || true
    printf "  "; print_error "$repo_name: fetch failed"
    exit 1
  fi

  # Check if behind upstream
  local upstream behind
  upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
  [[ -z "$upstream" ]] && { $stashed && git stash pop &>/dev/null || true; exit 2; }
  behind=$(git rev-list HEAD.."@{upstream}" --count 2>/dev/null || echo "0")
  if [[ "$behind" -eq 0 ]]; then
    $stashed && git stash pop &>/dev/null || true
    exit 2
  fi

  $DRY_RUN && { $stashed && git stash pop &>/dev/null || true; printf "  "; print_info "$repo_name: $behind commits behind"; exit 0; }

  if git pull --rebase &>/dev/null; then
    $stashed && { git stash pop &>/dev/null || print_warning "$repo_name: stash conflict"; }
    printf "  "; print_success "$repo_name: updated ($behind commits)"
    exit 0
  else
    git rebase --abort &>/dev/null || true
    $stashed && git stash pop &>/dev/null || true
    printf "  "; print_error "$repo_name: pull failed"
    exit 1
  fi
}

acquire_lock "update-repos" || exit 0
require_cmd "git" || exit 1
[[ -d "$REPOS_DIR" ]] || { print_error "Directory not found: $REPOS_DIR"; exit 1; }

curl -sf --max-time 5 --head https://github.com &>/dev/null || print_warning "Network may be unavailable"

print_header "Updating Git Repositories"
$DRY_RUN && print_warning "DRY RUN"

# Find repos, filter submodules
raw_repos=$(find "$REPOS_DIR" -maxdepth 5 -type d -name ".git" \
  -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/.cache/*" \
  -not -path "*/.build/*" -not -path "*/Pods/*" -not -path "*/.git/modules/*" 2>/dev/null)
[[ -z "$raw_repos" ]] && { print_info "No repositories found"; exit 0; }

repos=""
while IFS= read -r p; do
  [[ -z "$p" ]] && continue
  is_submodule "$p" || repos+="$p"$'\n'
done <<< "$raw_repos"
repos=$(printf '%s' "$repos" | sed '/^$/d')
[[ -z "$repos" ]] && { print_info "No repositories found (all submodules)"; exit 0; }

total=$(echo "$repos" | wc -l | xargs)
print_info "Found $total repositories"
printf '\n'

if [[ "$JOBS" -gt 1 ]] && command -v parallel &>/dev/null; then
  result_log=$(mktemp)
  export DRY_RUN FETCH_TIMEOUT REPOS_DIR
  export -f update_repo is_submodule
  echo "$repos" | parallel --jobs "$JOBS" --keep-order --joblog "$result_log" update_repo || true
  UPDATED=$(awk 'NR>1 && $7==0' "$result_log" | wc -l | xargs)
  FAILED=$(awk 'NR>1 && $7==1' "$result_log" | wc -l | xargs)
  SKIPPED=$(awk 'NR>1 && $7==2' "$result_log" | wc -l | xargs)
  rm -f "$result_log"
else
  while IFS= read -r repo; do
    local_result=0
    (update_repo "$repo") || local_result=$?
    case $local_result in
      0) UPDATED=$((UPDATED + 1)) ;; 1) FAILED=$((FAILED + 1)) ;; 2) SKIPPED=$((SKIPPED + 1)) ;;
    esac
  done <<< "$repos"
fi

printf '\n'
print_header "Summary"
print_key_value "Updated" "$UPDATED"
print_key_value "Skipped" "$SKIPPED"
[[ $FAILED -gt 0 ]] && { print_key_value "Failed" "$FAILED"; exit 1; }
print_success "All repositories processed"
