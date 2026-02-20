#!/usr/bin/env bash
# Update all git repositories in Developer directory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

UPDATED=0
FAILED=0
SKIPPED=0
UP_TO_DATE=0
REPOS_DIR="$HOME/Developer"
DRY_RUN=false
DEVELOPER_ROOT="${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"

LOG_DIR="$HOME/.local/log"
LOG_FILE="$LOG_DIR/repo-updates-$(date +%Y-%m-%d).log"
mkdir -p "$LOG_DIR"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--dry-run] [path]

Update all git repositories under the provided path (default: \$DOTFILES_DEVELOPER_ROOT).
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
  local repo_name current_branch upstream behind
  repo_name="$(basename "$(dirname "$repo_path")")"

  cd "$(dirname "$repo_path")" || return 1

  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    printf "  "
    print_warning "$repo_name: Skipped (uncommitted changes)"
    log "⚠ $repo_name: Skipped (uncommitted changes)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

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
          UPDATED=$((UPDATED + 1))
        else
          if git pull --rebase &>/dev/null; then
            printf "  "
            print_success "$repo_name: Updated ($behind commits on $current_branch)"
            log "✓ $repo_name: Updated ($behind commits pulled on $current_branch)"
            UPDATED=$((UPDATED + 1))
          else
            printf "  "
            print_error "$repo_name: Failed to pull on $current_branch"
            log "✗ $repo_name: Failed to pull on $current_branch"
            FAILED=$((FAILED + 1))
            git rebase --abort &>/dev/null || true
          fi
        fi
      else
        printf "  "
        print_dim "$repo_name: Up to date on $current_branch"
        UP_TO_DATE=$((UP_TO_DATE + 1))
      fi
    else
      printf "  "
      print_dim "$repo_name: Fetched (no tracking branch for $current_branch)"
      UP_TO_DATE=$((UP_TO_DATE + 1))
    fi
  else
    printf "  "
    print_error "$repo_name: Failed to fetch"
    log "✗ $repo_name: Failed to fetch"
    FAILED=$((FAILED + 1))
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

  while IFS= read -r repo; do
    update_repo "$repo"
  done <<< "$repos"

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
