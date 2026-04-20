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
QUIET=false
COMPACT=false
JOBS=15
FETCH_TIMEOUT=30
SKIP_RECENT_SECONDS=300
NO_CACHE=false
FAILURE_LOG="$HOME/.local/log/update-repos-failures.log"
DEVELOPER_ROOT="$DOTFILES_DEVELOPER_ROOT"
CACHE_DIR="$HOME/.cache/dotfiles"
CACHE_FILE="$CACHE_DIR/update-repos-list.txt"
CACHE_TTL=3600

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run] [--quiet] [--compact] [--jobs N] [--timeout N] [--skip-recent N] [--no-cache] [path]

Update all git repositories under the provided path (default: \$DOTFILES_DEVELOPER_ROOT).

For each repo, detects the base branch (main/master/develop/staging) and:
  - If on the base branch: pulls with rebase
  - If on a feature branch: fast-forwards the base branch and rebases onto it

Options:
  --jobs N, -j N       Parallel jobs (default: 15)
  --timeout N, -t N    Fetch timeout in seconds (default: 30)
  --skip-recent N      Skip fetch for repos fetched within N seconds (default: 300, 0 to disable)
  --no-cache           Force repo discovery instead of using cached list
  --dry-run            Preview without making changes
  --quiet              One-line summary only
  --compact            Stream only updated/failed repositories plus summary
  --no-color           Disable colored output
EOF
}

REPOS_DIR="$DEVELOPER_ROOT"
show_help_if_requested usage "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color) shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --quiet) QUIET=true; shift ;;
    --compact) COMPACT=true; shift ;;
    --jobs|-j) JOBS="$2"; shift 2 ;;
    --timeout|-t) FETCH_TIMEOUT="$2"; shift 2 ;;
    --skip-recent) SKIP_RECENT_SECONDS="$2"; shift 2 ;;
    --no-cache) NO_CACHE=true; shift ;;
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

# Detect the default/base branch for the current repo
detect_base_branch() {
  local ref
  ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || echo "")
  if [[ -n "$ref" ]]; then
    echo "${ref#refs/remotes/origin/}"
    return
  fi
  for candidate in main master develop staging; do
    if git show-ref --verify --quiet "refs/remotes/origin/$candidate" 2>/dev/null; then
      echo "$candidate"
      return
    fi
  done
  echo ""
}

# Classify fetch failure from stderr output
classify_fetch_failure() {
  local output="$1"
  case "$output" in
    *"timed out"*|*"timeout"*|*"Could not resolve"*|*"unable to access"*)
      echo "network/timeout" ;;
    *"Authentication"*|*"Permission denied"*|*"could not read"*|*"403"*)
      echo "auth failure" ;;
    *) echo "fetch error" ;;
  esac
}

# Print a failure/warning message respecting output mode
report_msg() {
  local repo_name="$1" level="$2" msg="$3"
  $QUIET && return
  if $COMPACT; then
    print_status_row "$repo_name" "$level" "$msg"
  else
    printf "  "
    case "$level" in
      ok) print_success "$repo_name: $msg" ;;
      error) print_error "$repo_name: $msg" ;;
      warn) print_warning "$repo_name: $msg" ;;
      info) print_info "$repo_name: $msg" ;;
    esac
  fi
}

update_repo() {
  local repo_path="$1"
  local repo_name repo_dir
  repo_dir="$(dirname "$repo_path")"
  repo_name="$(basename "$repo_dir")"

  cd "$repo_dir" || exit 1

  # Skip: bare repos, no commits, detached HEAD, rebase/merge in progress, index.lock
  [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]] && exit 2
  git rev-parse HEAD &>/dev/null || exit 2
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  [[ "$branch" == "HEAD" || -z "$branch" ]] && exit 2
  local gd
  gd="$(git rev-parse --git-dir 2>/dev/null)"
  [[ -d "$gd/rebase-merge" || -d "$gd/rebase-apply" || -f "$gd/MERGE_HEAD" || -f "$gd/index.lock" ]] && exit 2

  # Detect base branch
  local base_branch
  base_branch=$(detect_base_branch)

  # Stash uncommitted changes
  local stashed=false
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    $DRY_RUN && {
      local dry_detail="would stash and update"
      if [[ -n "$base_branch" && "$branch" != "$base_branch" ]]; then
        dry_detail="would stash, update $base_branch, and rebase $branch"
      elif [[ -n "$base_branch" ]]; then
        dry_detail="would stash and update $base_branch"
      fi
      report_msg "$repo_name" info "$dry_detail"
      exit 0
    }
    git stash push --include-untracked -m "update-repos: auto-stash" &>/dev/null && stashed=true || exit 2
  fi

  # Restore stash helper
  restore_stash() {
    if $stashed; then
      if ! git stash pop &>/dev/null; then
        report_msg "$repo_name" warn "stash conflict — resolve with: cd $repo_dir && git stash show && git stash pop"
      fi
    fi
  }

  # Check if we can skip fetch (recently fetched)
  local skip_fetch=false
  if [[ "$SKIP_RECENT_SECONDS" -gt 0 && -f "$gd/FETCH_HEAD" ]]; then
    local now fetch_mtime fetch_age
    now=$(date +%s)
    fetch_mtime=$(stat -f %m "$gd/FETCH_HEAD" 2>/dev/null || echo 0)
    fetch_age=$(( now - fetch_mtime ))
    if [[ $fetch_age -lt $SKIP_RECENT_SECONDS ]]; then
      skip_fetch=true
    fi
  fi

  # Fetch with timeout and retry for transient failures
  if ! $skip_fetch; then
    local fetch_cmd="git fetch --all --prune"
    if command -v gtimeout &>/dev/null; then fetch_cmd="gtimeout $FETCH_TIMEOUT $fetch_cmd"
    elif command -v timeout &>/dev/null; then fetch_cmd="timeout $FETCH_TIMEOUT $fetch_cmd"; fi

    local fetch_output="" fetch_exit=0
    fetch_output=$(eval "$fetch_cmd" 2>&1) || fetch_exit=$?

    if [[ $fetch_exit -ne 0 ]]; then
      local fail_reason
      fail_reason=$(classify_fetch_failure "$fetch_output")

      # Retry transient (network) failures, not auth failures
      if [[ "$fail_reason" == "network/timeout" ]]; then
        local retry_ok=false
        for attempt in 1 2; do
          sleep $((attempt * 5))
          if eval "$fetch_cmd" &>/dev/null; then
            retry_ok=true
            break
          fi
        done
        if ! $retry_ok; then
          restore_stash
          report_msg "$repo_name" error "$fail_reason (retried)"
          [[ -n "${FAILURE_LOG:-}" ]] && log_msg "$FAILURE_LOG" "$repo_name: $fail_reason (retried)"
          exit 1
        fi
      else
        restore_stash
        report_msg "$repo_name" error "$fail_reason"
        [[ -n "${FAILURE_LOG:-}" ]] && log_msg "$FAILURE_LOG" "$repo_name: $fail_reason"
        exit 1
      fi
    fi
  fi

  # No base branch detected — fall back to simple pull --rebase
  if [[ -z "$base_branch" ]]; then
    local upstream behind
    upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
    [[ -z "$upstream" ]] && { restore_stash; exit 2; }
    behind=$(git rev-list HEAD.."@{upstream}" --count 2>/dev/null || echo "0")
    if [[ "$behind" -eq 0 ]]; then
      restore_stash; exit 2
    fi
    $DRY_RUN && { restore_stash; report_msg "$repo_name" info "would update ($behind commits behind)"; exit 0; }
    if git pull --rebase &>/dev/null; then
      restore_stash
      report_msg "$repo_name" ok "updated ($behind commits)"
      exit 0
    else
      git rebase --abort &>/dev/null || true
      restore_stash
      report_msg "$repo_name" error "pull failed"
      [[ -n "${FAILURE_LOG:-}" ]] && log_msg "$FAILURE_LOG" "$repo_name: pull --rebase failed (no base branch detected)"
      exit 1
    fi
  fi

  # --- Base branch detected: smart update ---

  if [[ "$branch" == "$base_branch" ]]; then
    # On the base branch — pull with rebase
    local behind
    behind=$(git rev-list HEAD.."origin/$base_branch" --count 2>/dev/null || echo "0")
    if [[ "$behind" -eq 0 ]]; then
      restore_stash; exit 2
    fi
    $DRY_RUN && { restore_stash; report_msg "$repo_name" info "would update $base_branch ($behind commits behind)"; exit 0; }
    if git pull --rebase &>/dev/null; then
      restore_stash
      report_msg "$repo_name" ok "updated $base_branch ($behind commits)"
      exit 0
    else
      git rebase --abort &>/dev/null || true
      restore_stash
      report_msg "$repo_name" error "pull failed on $base_branch"
      [[ -n "${FAILURE_LOG:-}" ]] && log_msg "$FAILURE_LOG" "$repo_name: pull --rebase failed on $base_branch"
      exit 1
    fi
  else
    # On a feature branch — fast-forward the base branch, then rebase
    local base_updated=false base_behind
    base_behind=$(git rev-list "${base_branch}..origin/${base_branch}" --count 2>/dev/null || echo "0")

    if [[ "$base_behind" -gt 0 ]]; then
      $DRY_RUN && {
        local feat_behind
        feat_behind=$(git rev-list HEAD.."$base_branch" --count 2>/dev/null || echo "0")
        restore_stash
        report_msg "$repo_name" info "would update $base_branch (+$base_behind) and rebase $branch"
        exit 0
      }
      # Fast-forward base branch without checkout
      if git fetch origin "$base_branch:$base_branch" &>/dev/null; then
        base_updated=true
      else
        report_msg "$repo_name" warn "$base_branch has local commits — skipped fast-forward"
      fi
    fi

    # Rebase feature branch onto base
    local feat_behind
    feat_behind=$(git rev-list HEAD.."$base_branch" --count 2>/dev/null || echo "0")

    if [[ "$feat_behind" -eq 0 ]] && ! $base_updated; then
      # Also check if the feature branch's own upstream has updates
      local upstream_behind=0
      local upstream
      upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
      if [[ -n "$upstream" ]]; then
        upstream_behind=$(git rev-list HEAD.."@{upstream}" --count 2>/dev/null || echo "0")
      fi
      if [[ "$upstream_behind" -eq 0 ]]; then
        restore_stash; exit 2
      fi
      # Pull own upstream changes
      $DRY_RUN && { restore_stash; report_msg "$repo_name" info "would update $branch ($upstream_behind commits behind upstream)"; exit 0; }
      if git pull --rebase &>/dev/null; then
        restore_stash
        report_msg "$repo_name" ok "updated $branch ($upstream_behind commits from upstream)"
        exit 0
      else
        git rebase --abort &>/dev/null || true
        restore_stash
        report_msg "$repo_name" error "pull failed on $branch"
        [[ -n "${FAILURE_LOG:-}" ]] && log_msg "$FAILURE_LOG" "$repo_name: pull --rebase failed on $branch"
        exit 1
      fi
    fi

    $DRY_RUN && { restore_stash; report_msg "$repo_name" info "would rebase $branch onto $base_branch (+$feat_behind)"; exit 0; }

    local rebase_output=""
    rebase_output=$(git rebase "$base_branch" 2>&1) || {
      local rebase_reason="rebase failed"
      [[ "$rebase_output" == *"CONFLICT"* ]] && rebase_reason="rebase conflict with $base_branch"
      git rebase --abort &>/dev/null || true
      restore_stash
      report_msg "$repo_name" error "$rebase_reason"
      [[ -n "${FAILURE_LOG:-}" ]] && log_msg "$FAILURE_LOG" "$repo_name: $rebase_reason on $branch"
      exit 1
    }

    # Also pull feature branch's own upstream if it has one
    local upstream
    upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
    if [[ -n "$upstream" ]]; then
      local upstream_behind
      upstream_behind=$(git rev-list HEAD.."@{upstream}" --count 2>/dev/null || echo "0")
      if [[ "$upstream_behind" -gt 0 ]]; then
        git pull --rebase &>/dev/null || true
      fi
    fi

    restore_stash
    local detail="rebased $branch onto $base_branch"
    $base_updated && detail="updated $base_branch (+$base_behind), $detail"
    report_msg "$repo_name" ok "$detail"
    exit 0
  fi
}

acquire_lock "update-repos" || exit 0
require_cmd "git" || exit 1
[[ -d "$REPOS_DIR" ]] || { print_error "Directory not found: $REPOS_DIR"; exit 1; }

# Prepare failure log
mkdir -p "$(dirname "$FAILURE_LOG")"
: > "$FAILURE_LOG"

curl -sf --max-time 5 --head https://github.com &>/dev/null || { $QUIET || print_warning "Network may be unavailable"; }

# Find repos — use cache if available and fresh
use_cache=false
if ! $NO_CACHE && [[ -f "$CACHE_FILE" ]]; then
  local_now=$(date +%s)
  cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  cache_age=$(( local_now - cache_mtime ))
  if [[ $cache_age -lt $CACHE_TTL ]]; then
    use_cache=true
  fi
fi

if $use_cache; then
  repos=$(cat "$CACHE_FILE")
else
  raw_repos=$(find "$REPOS_DIR" -maxdepth 5 -type d -name ".git" \
    -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/.cache/*" \
    -not -path "*/.build/*" -not -path "*/Pods/*" -not -path "*/.git/modules/*" 2>/dev/null)
  if [[ -z "$raw_repos" ]]; then
    if $QUIET; then echo "no repositories found"; else print_info "No repositories found"; fi
    exit 0
  fi

  repos=""
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    is_submodule "$p" || repos+="$p"$'\n'
  done <<< "$raw_repos"
  repos=$(printf '%s' "$repos" | sed '/^$/d')

  # Write cache
  mkdir -p "$CACHE_DIR"
  printf '%s\n' "$repos" > "$CACHE_FILE"
fi

if [[ -z "$repos" ]]; then
  if $QUIET; then echo "no repositories found"; else print_info "No repositories found (all submodules)"; fi
  exit 0
fi

total=$(echo "$repos" | wc -l | xargs)

if ! $QUIET; then
  if ! $COMPACT; then
    print_header "Updating Git Repositories"
    $DRY_RUN && print_warning "DRY RUN"
    print_info "Found $total repositories"
    printf '\n'
  fi
fi

if [[ "$JOBS" -gt 1 ]] && command -v parallel &>/dev/null; then
  result_log=$(mktemp)
  export DRY_RUN FETCH_TIMEOUT REPOS_DIR QUIET COMPACT SKIP_RECENT_SECONDS FAILURE_LOG
  export -f update_repo is_submodule detect_base_branch classify_fetch_failure report_msg
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

if $QUIET; then
  local_parts=()
  [[ $UPDATED -gt 0 ]] && local_parts+=("$UPDATED updated")
  [[ $SKIPPED -gt 0 ]] && local_parts+=("$SKIPPED skipped")
  [[ $FAILED -gt 0 ]] && local_parts+=("$FAILED failed")
  IFS=', '; echo "${local_parts[*]}"
  if [[ $FAILED -gt 0 ]]; then exit 1; fi
  exit 0
else
  printf '\n'
  if $COMPACT; then
    print_status_row "Updated" info "$UPDATED"
    print_status_row "Skipped" info "$SKIPPED"
    if [[ $FAILED -gt 0 ]]; then
      print_status_row "Failed" error "$FAILED"
    else
      print_status_row "Failed" info "0"
    fi
  else
    print_key_value "Updated" "$UPDATED"
    print_key_value "Skipped" "$SKIPPED"
    [[ $FAILED -gt 0 ]] && print_key_value "Failed" "$FAILED"
  fi
  printf '\n'
  if [[ $FAILED -gt 0 ]]; then
    print_warning "Repository updates completed with issues"
    print_info "Failure details: $FAILURE_LOG"
    exit 1
  fi
  print_success "Repository updates complete"
fi
