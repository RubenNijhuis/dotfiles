#!/usr/bin/env bash
# Update all git repositories in Developer directory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/env.sh"
dotfiles_load_env "$(cd "$SCRIPT_DIR/../.." && pwd)"

UPDATED=0
FAILED=0
SKIPPED=0
UP_TO_DATE=0
DRY_RUN=false
JOBS=15
FETCH_TIMEOUT=30
DEVELOPER_ROOT="$DOTFILES_DEVELOPER_ROOT"

LOG_DIR="$HOME/.local/log"
LOG_FILE="$LOG_DIR/repo-updates-$(date +%Y-%m-%d).log"
mkdir -p "$LOG_DIR"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run] [--jobs N] [--timeout N] [path]

Update all git repositories under the provided path (default: \$DOTFILES_DEVELOPER_ROOT).

Options:
  --jobs N, -j N     Number of parallel jobs (default: 15, 1 = sequential)
  --timeout N, -t N  Fetch timeout in seconds per repo (default: 30)
  --dry-run          Show what would be updated without making changes
  --no-color         Disable colored output
  --help             Show this help message
EOF
}

parse_args() {
  REPOS_DIR="$DEVELOPER_ROOT"
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
      --jobs|-j)
        if [[ -z "${2:-}" || ! "${2:-}" =~ ^[0-9]+$ || "${2:-}" -eq 0 ]]; then
          print_error "--jobs requires a positive numeric argument"
          exit 1
        fi
        JOBS="$2"
        shift 2
        ;;
      --timeout|-t)
        if [[ -z "${2:-}" || ! "${2:-}" =~ ^[0-9]+$ || "${2:-}" -eq 0 ]]; then
          print_error "--timeout requires a positive numeric argument"
          exit 1
        fi
        FETCH_TIMEOUT="$2"
        shift 2
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

log() {
  log_msg "$LOG_FILE" "$1"
}

# Check if a .git path belongs to a submodule (file-based .git reference)
is_submodule() {
  local git_path="$1"
  local parent_dir
  parent_dir="$(dirname "$git_path")"

  # Submodules have a .git file (not directory) pointing to the parent's .git/modules/
  # But our find already filters for -type d, so check if this repo lives inside
  # another repo's worktree
  local check_dir
  check_dir="$(dirname "$parent_dir")"
  while [[ "$check_dir" != "/" && "$check_dir" != "$REPOS_DIR" ]]; do
    if [[ -d "$check_dir/.git" || -f "$check_dir/.git" ]]; then
      return 0  # This is nested inside another repo — likely a submodule
    fi
    check_dir="$(dirname "$check_dir")"
  done
  return 1
}

restore_stash() {
  local stashed="$1"
  local repo_name="$2"
  if $stashed; then
    if ! git stash pop &>/dev/null; then
      printf "  "
      print_warning "$repo_name: Could not restore stash (run 'git stash pop' manually)"
      log "⚠ $repo_name: Stash pop failed"
    fi
  fi
}

update_repo() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$(dirname "$repo_path")")"

  # Exit codes: 0=updated, 1=failed, 2=skipped, 3=up-to-date
  # parallel runs each invocation in its own process, so exit codes
  # propagate to the joblog. Sequential fallback wraps calls in a subshell.
  cd "$(dirname "$repo_path")" || exit 1

  # Skip bare repositories — they have no worktree to update
  if [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]]; then
    printf "  "
    print_dim "$repo_name: Skipped (bare repository)"
    exit 3
  fi

  # Skip repos with no commits yet
  if ! git rev-parse HEAD &>/dev/null; then
    printf "  "
    print_dim "$repo_name: Skipped (no commits)"
    exit 3
  fi

  # Skip repos in detached HEAD state — no branch to pull into
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  if [[ "$current_branch" == "HEAD" || "$current_branch" == "unknown" ]]; then
    printf "  "
    print_dim "$repo_name: Skipped (detached HEAD)"
    exit 3
  fi

  # Skip repos in the middle of a rebase, merge, or cherry-pick
  local git_dir
  git_dir="$(git rev-parse --git-dir 2>/dev/null)"
  if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" || -f "$git_dir/MERGE_HEAD" || -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
    printf "  "
    print_warning "$repo_name: Skipped (rebase/merge in progress)"
    log "⚠ $repo_name: Skipped (rebase/merge in progress)"
    exit 2
  fi

  # Skip repos with a lock file — another git process is running
  if [[ -f "$git_dir/index.lock" ]]; then
    printf "  "
    print_warning "$repo_name: Skipped (index.lock present, another git process running?)"
    log "⚠ $repo_name: Skipped (index.lock present)"
    exit 2
  fi

  # Stash uncommitted changes before updating
  local stashed=false
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    if $DRY_RUN; then
      printf "  "
      print_info "$repo_name: Would stash and update (uncommitted changes)"
      log "ℹ $repo_name: Would stash and update (dry-run)"
      exit 0
    fi
    if git stash push --include-untracked -m "update-repos: auto-stash" &>/dev/null; then
      stashed=true
    else
      printf "  "
      print_warning "$repo_name: Skipped (stash failed)"
      log "⚠ $repo_name: Skipped (stash failed)"
      exit 2
    fi
  fi

  # Fetch with timeout and retry to handle transient network issues
  # shellcheck disable=SC2329  # Invoked indirectly via retry.
  fetch_once() {
    if command -v gtimeout &>/dev/null; then
      gtimeout "$FETCH_TIMEOUT" git fetch --all --prune &>/dev/null
    elif command -v timeout &>/dev/null; then
      timeout "$FETCH_TIMEOUT" git fetch --all --prune &>/dev/null
    else
      git fetch --all --prune &>/dev/null
    fi
  }
  local fetch_ok=false
  retry 2 fetch_once && fetch_ok=true

  if ! $fetch_ok; then
    restore_stash "$stashed" "$repo_name"
    printf "  "
    print_error "$repo_name: Failed to fetch (timeout or network error)"
    log "✗ $repo_name: Failed to fetch"
    exit 1
  fi

  local upstream behind
  upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")

  if [[ -z "$upstream" ]]; then
    restore_stash "$stashed" "$repo_name"
    printf "  "
    print_dim "$repo_name: Fetched (no tracking branch for $current_branch)"
    exit 3
  fi

  behind=$(git rev-list HEAD..@{upstream} --count 2>/dev/null || echo "0")

  if [[ "$behind" -eq 0 ]]; then
    restore_stash "$stashed" "$repo_name"
    printf "  "
    print_dim "$repo_name: Up to date on $current_branch"
    exit 3
  fi

  if $DRY_RUN; then
    restore_stash "$stashed" "$repo_name"
    printf "  "
    print_info "$repo_name: Would update ($behind commits on $current_branch)"
    log "ℹ $repo_name: Would pull $behind commits on $current_branch (dry-run)"
    exit 0
  fi

  if git pull --rebase &>/dev/null; then
    local stash_note=""
    if $stashed; then
      if git stash pop &>/dev/null; then
        stash_note=", stash restored"
      else
        stash_note=", stash conflict (run 'git stash pop' manually)"
        printf "  "
        print_warning "$repo_name: Stash could not be re-applied cleanly"
        log "⚠ $repo_name: Stash pop failed after update"
      fi
    fi
    printf "  "
    print_success "$repo_name: Updated ($behind commits on $current_branch$stash_note)"
    log "✓ $repo_name: Updated ($behind commits pulled on $current_branch$stash_note)"
    exit 0
  else
    printf "  "
    print_error "$repo_name: Failed to pull on $current_branch"
    log "✗ $repo_name: Failed to pull on $current_branch"
    git rebase --abort &>/dev/null || true
    restore_stash "$stashed" "$repo_name"
    exit 1
  fi
}

filter_repos() {
  local repos="$1"
  local filtered=""

  while IFS= read -r repo_path; do
    [[ -z "$repo_path" ]] && continue

    # Skip submodules (repos nested inside other repos)
    if is_submodule "$repo_path"; then
      continue
    fi

    filtered+="$repo_path"$'\n'
  done <<< "$repos"

  # Remove trailing newline
  printf '%s' "$filtered" | sed '/^$/d'
}

main() {
  parse_args "$@"
  acquire_lock "update-repos" || exit 0

  require_cmd "git" "Install Git first: brew install git" || exit 1

  if [[ ! -d "$REPOS_DIR" ]]; then
    print_error "Directory not found: $REPOS_DIR"
    exit 1
  fi

  # Quick network connectivity check
  if ! curl -sf --max-time 5 --head https://github.com &>/dev/null; then
    print_warning "Network may be unavailable — fetches might fail"
  fi

  print_header "Updating Git Repositories"
  if $DRY_RUN; then
    print_warning "DRY RUN: no repositories will be modified"
  fi
  log "Starting repository updates in $REPOS_DIR..."

  local raw_repos
  raw_repos=$(find "$REPOS_DIR" -maxdepth 5 -type d -name ".git" \
    -not -path "*/node_modules/*" \
    -not -path "*/vendor/*" \
    -not -path "*/.cache/*" \
    -not -path "*/.build/*" \
    -not -path "*/Pods/*" \
    -not -path "*/.git/modules/*" \
    2>/dev/null)

  if [[ -z "$raw_repos" ]]; then
    print_warning "No repositories found in $REPOS_DIR"
    log "No repositories found in $REPOS_DIR"
    exit 0
  fi

  # Filter out submodules
  local repos
  repos=$(filter_repos "$raw_repos")

  if [[ -z "$repos" ]]; then
    print_warning "No repositories found in $REPOS_DIR (all filtered as submodules)"
    log "No repositories found after filtering"
    exit 0
  fi

  local total
  total=$(echo "$repos" | wc -l | xargs)
  print_section "Found $total repositories"
  log "Found $total repositories"
  printf "\n"

  if [[ "$JOBS" -gt 1 ]] && command -v parallel &>/dev/null; then
    # Parallel execution
    local result_log
    result_log=$(mktemp)

    export DRY_RUN LOG_FILE FETCH_TIMEOUT
    export -f update_repo log restore_stash

    echo "$repos" | parallel --jobs "$JOBS" --keep-order --joblog "$result_log" \
      update_repo || true

    # Tally from joblog (column 7 = Exitval, skip header)
    UPDATED=$(awk 'NR>1 && $7==0' "$result_log" | wc -l | xargs)
    FAILED=$(awk 'NR>1 && $7==1' "$result_log" | wc -l | xargs)
    SKIPPED=$(awk 'NR>1 && $7==2' "$result_log" | wc -l | xargs)
    UP_TO_DATE=$(awk 'NR>1 && $7==3' "$result_log" | wc -l | xargs)
    rm -f "$result_log"
  else
    # Sequential fallback
    if [[ "$JOBS" -gt 1 ]]; then
      print_warning "GNU parallel not found, falling back to sequential execution"
    fi

    while IFS= read -r repo; do
      local result=0
      (update_repo "$repo") || result=$?
      case $result in
        0) UPDATED=$((UPDATED + 1)) ;;
        1) FAILED=$((FAILED + 1)) ;;
        2) SKIPPED=$((SKIPPED + 1)) ;;
        3) UP_TO_DATE=$((UP_TO_DATE + 1)) ;;
      esac
    done <<< "$repos"
  fi

  # Clean up log lock file
  rm -f "${LOG_FILE}.lock"

  printf "\n"
  print_header "Update Summary"
  print_key_value "Updated" "$UPDATED repositories"
  print_key_value "Up to date" "$UP_TO_DATE repositories"

  if [[ $SKIPPED -gt 0 ]]; then
    print_key_value "Skipped" "$SKIPPED repositories"
  fi

  if [[ $FAILED -gt 0 ]]; then
    print_key_value "Failed" "$FAILED repositories"
    printf "\n"
    print_error "Some repositories failed to update"
    print_info "Check log file: $LOG_FILE"
    exit 1
  fi

  printf "\n"
  print_success "All repositories updated successfully"
  print_info "Log saved to: $LOG_FILE"
}

main "$@"
