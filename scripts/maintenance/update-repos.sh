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
JOBS=4
DEVELOPER_ROOT="$DOTFILES_DEVELOPER_ROOT"

LOG_DIR="$HOME/.local/log"
LOG_FILE="$LOG_DIR/repo-updates-$(date +%Y-%m-%d).log"
mkdir -p "$LOG_DIR"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--dry-run] [--jobs N] [path]

Update all git repositories under the provided path (default: \$DOTFILES_DEVELOPER_ROOT).

Options:
  --jobs N, -j N  Number of parallel jobs (default: 4, 1 = sequential)
  --dry-run       Show what would be updated without making changes
  --no-color      Disable colored output
  --help          Show this help message
EOF2
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
        if [[ -z "${2:-}" || "${2#-}" != "$2" ]]; then
          print_error "--jobs requires a numeric argument"
          exit 1
        fi
        JOBS="$2"
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
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

update_repo() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$(dirname "$repo_path")")"

  # Exit codes: 0=updated, 1=failed, 2=skipped, 3=up-to-date
  # parallel runs each invocation in its own process, so exit codes
  # propagate to the joblog. Sequential fallback wraps calls in a subshell.
  cd "$(dirname "$repo_path")" || exit 1

  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    printf "  "
    print_warning "$repo_name: Skipped (uncommitted changes)"
    log "⚠ $repo_name: Skipped (uncommitted changes)"
    exit 2
  fi

  local current_branch upstream behind
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  if git fetch --all --prune &>/dev/null; then
    upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")

    if [[ -n "$upstream" ]]; then
      behind=$(git rev-list HEAD..@{upstream} --count 2>/dev/null || echo "0")

      if [[ "$behind" -gt 0 ]]; then
        if $DRY_RUN; then
          printf "  "
          print_info "$repo_name: Would update ($behind commits on $current_branch)"
          log "ℹ $repo_name: Would pull $behind commits on $current_branch (dry-run)"
          exit 0
        else
          if git pull --rebase &>/dev/null; then
            printf "  "
            print_success "$repo_name: Updated ($behind commits on $current_branch)"
            log "✓ $repo_name: Updated ($behind commits pulled on $current_branch)"
            exit 0
          else
            printf "  "
            print_error "$repo_name: Failed to pull on $current_branch"
            log "✗ $repo_name: Failed to pull on $current_branch"
            git rebase --abort &>/dev/null || true
            exit 1
          fi
        fi
      else
        printf "  "
        print_dim "$repo_name: Up to date on $current_branch"
        exit 3
      fi
    else
      printf "  "
      print_dim "$repo_name: Fetched (no tracking branch for $current_branch)"
      exit 3
    fi
  else
    printf "  "
    print_error "$repo_name: Failed to fetch"
    log "✗ $repo_name: Failed to fetch"
    exit 1
  fi
}

main() {
  parse_args "$@"

  require_cmd "git" "Install Git first: brew install git" >/dev/null || {
    print_error "Git is required"
    exit 1
  }

  if [[ ! -d "$REPOS_DIR" ]]; then
    print_error "Directory not found: $REPOS_DIR"
    exit 1
  fi

  print_header "Updating Git Repositories"
  if $DRY_RUN; then
    print_warning "DRY RUN: no repositories will be modified"
  fi
  log "Starting repository updates in $REPOS_DIR..."

  local repos
  repos=$(find "$REPOS_DIR" -type d -name ".git" -maxdepth 5 2>/dev/null)

  if [[ -z "$repos" ]]; then
    print_warning "No repositories found in $REPOS_DIR"
    log "No repositories found in $REPOS_DIR"
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

    export DRY_RUN LOG_FILE
    export -f update_repo log

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

  printf "\n"
  print_header "Update Summary"
  print_key_value "Updated" "$UPDATED repositories"
  print_key_value "Up to date" "$UP_TO_DATE repositories"

  if [[ $SKIPPED -gt 0 ]]; then
    print_key_value "Skipped" "$SKIPPED repositories (uncommitted changes)"
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
