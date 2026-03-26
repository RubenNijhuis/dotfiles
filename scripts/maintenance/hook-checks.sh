#!/usr/bin/env bash
# Shared checks used by git hooks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

MODE=""

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] <docs-sync|untracked-shell|large-files|commit-message|branch-status> [path ...]

Run shared git-hook checks.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"
  MODE_ARGS=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      docs-sync|untracked-shell|large-files|commit-message|branch-status)
        MODE="$1"
        shift
        MODE_ARGS=("$@")
        break
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "$MODE" ]]; then
    usage
    exit 1
  fi
}

check_docs_sync() {
  print_section "Checking generated docs..."
  if make -s docs-sync >/dev/null 2>&1; then
    print_success "Generated docs are in sync"
    return 0
  fi

  print_error "Generated docs are stale"
  print_info "Run: bash scripts/maintenance/generate-cli-reference.sh"
  return 1
}

check_untracked_shell() {
  print_section "Checking for untracked scripts..."
  local untracked
  untracked="$(git -C "$DOTFILES" ls-files --others --exclude-standard | grep -E '\.(sh|bash|zsh)$' || true)"

  if [[ -n "$untracked" ]]; then
    print_warning "Found untracked shell scripts:"
    while IFS= read -r file; do
      printf "  "
      print_dim "$file"
    done <<< "$untracked"
    print_info "Consider adding these to git or .gitignore"
  else
    print_success "No untracked shell scripts"
  fi
}

check_large_files() {
  print_section "Checking for large files..."
  local large_files=""
  local file

  for file in "${MODE_ARGS[@]}"; do
    [[ -f "$file" ]] || continue
    if [[ $(wc -c < "$file") -gt 1048576 ]]; then
      large_files+="$file"$'\n'
    fi
  done

  if [[ -n "$large_files" ]]; then
    print_error "Large files detected (>1MB):"
    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      local size
      size=$(du -h "$file" | cut -f1)
      printf "  "
      print_error "$file ($size)"
    done <<< "$large_files"
    print_info "Consider using Git LFS or excluding from repository"
    return 1
  fi

  print_success "No large files detected"
  return 0
}

check_commit_message() {
  print_section "Checking last commit message..."
  local last_commit_msg
  local last_commit_short

  last_commit_msg="$(git -C "$DOTFILES" log -1 --pretty=%B)"
  last_commit_short="$(echo "$last_commit_msg" | head -n 1)"

  if echo "$last_commit_short" | grep -qiE '^(wip|temp|fix|update|test)$'; then
    print_warning "Last commit message might be too generic:"
    printf "  "
    print_dim "$last_commit_short"
    print_info "Consider using more descriptive commit messages"
  elif [[ ${#last_commit_short} -lt 10 ]]; then
    print_warning "Last commit message is very short:"
    printf "  "
    print_dim "$last_commit_short"
  else
    print_success "Commit message looks good"
  fi
}

check_branch_status() {
  print_section "Checking branch status..."
  local current_branch
  local has_failures="${MODE_ARGS[0]:-false}"

  current_branch="$(git -C "$DOTFILES" branch --show-current)"
  if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
    if [[ "$has_failures" == "true" ]]; then
      print_error "Pushing to $current_branch with failures"
      print_info "Fix issues above before pushing to main branch"
      return 1
    fi
    print_success "Pushing to $current_branch - all checks passed"
  else
    print_info "Pushing to branch: $current_branch"
  fi
}

main() {
  parse_args "$@"

  case "$MODE" in
    docs-sync)
      check_docs_sync
      ;;
    untracked-shell)
      check_untracked_shell
      ;;
    large-files)
      check_large_files
      ;;
    commit-message)
      check_commit_message
      ;;
    branch-status)
      check_branch_status
      ;;
  esac
}

main "$@"
