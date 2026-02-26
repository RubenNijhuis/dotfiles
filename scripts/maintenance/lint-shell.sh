#!/usr/bin/env bash
# Lint shell scripts with syntax checks and shellcheck.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [path ...]

Run bash syntax and shellcheck linting across shell scripts.
When paths are provided, only lint those files.
EOF
}

is_shell_file() {
  local file="$1"
  [[ "$file" =~ \.(sh|bash|zsh)$ ]]
}

collect_files() {
  if [[ $# -gt 0 ]]; then
    local path
    for path in "$@"; do
      if [[ -f "$path" ]] && is_shell_file "$path"; then
        printf '%s\n' "$path"
      fi
    done
    return 0
  fi

  find "$DOTFILES" -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/.cache/*" | sort
}

parse_args() {
  show_help_if_requested usage "$@"

  LINT_TARGETS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      -*)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
      *)
        LINT_TARGETS+=("$1")
        shift
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  require_cmd "shellcheck" "Install shellcheck with: brew install shellcheck" >/dev/null || {
    print_error "shellcheck is required"
    exit 1
  }

  files=()
  if [[ ${#LINT_TARGETS[@]} -gt 0 ]]; then
    while IFS= read -r file; do
      files+=("$file")
    done < <(collect_files "${LINT_TARGETS[@]}")
  else
    while IFS= read -r file; do
      files+=("$file")
    done < <(collect_files)
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    print_info "No shell files to lint"
    exit 0
  fi

  print_header "Shell Lint"
  print_info "Checking ${#files[@]} files"
  printf '\n'

  print_section "bash -n"
  printf '%s\0' "${files[@]}" | xargs -0 bash -n
  print_success "Syntax checks passed"
  printf '\n'

  print_section "shellcheck"
  printf '%s\0' "${files[@]}" | xargs -0 shellcheck
  print_success "Shellcheck passed"
}

main "$@"
