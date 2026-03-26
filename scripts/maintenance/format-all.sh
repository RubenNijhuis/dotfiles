#!/usr/bin/env bash
# Format all files using Biome and ensure shell scripts are executable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Run Biome formatting on JS/TS/JSON files and ensure shell scripts are executable.
EditorConfig handles whitespace, line endings, and indentation via your editor.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color) shift ;;
      *) print_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done
}

parse_args "$@"
print_header "Format All"

# Biome formatting
if command -v biome &>/dev/null; then
  print_section "Running Biome..."
  biome check --write "$DOTFILES" 2>&1 | tail -1 || true
  print_success "Biome formatting complete"
else
  print_warning "Biome not installed — skipping (brew install biome)"
fi

# Ensure shell scripts are executable
FIXED=0
while IFS= read -r file; do
  if [[ -f "$file" && ! -x "$file" ]]; then
    chmod +x "$file"
    FIXED=$((FIXED + 1))
  fi
done < <(find "$DOTFILES/scripts" "$DOTFILES/git-hooks" -name "*.sh" -o -name "pre-commit" -o -name "pre-push" -o -name "commit-msg" 2>/dev/null)

if [[ $FIXED -gt 0 ]]; then
  print_warning "$FIXED script(s) made executable"
else
  print_success "All scripts already executable"
fi
