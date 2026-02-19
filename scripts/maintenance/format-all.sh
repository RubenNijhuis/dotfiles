#!/usr/bin/env bash
# Apply EditorConfig formatting rules to all files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Apply EditorConfig-style cleanup and Biome formatting across the repository.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

parse_args "$@"

print_header "Applying EditorConfig Formatting"

# Count files to process
TOTAL_FILES=0
FIXED_FILES=0
BIOME_FIXED=0

# Find all text files (excluding .git and node_modules)
FILES=$(find "$DOTFILES" -type f \
  \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \
  -o -name "*.yml" -o -name "*.yaml" \
  -o -name "*.json" -o -name "*.jsonc" \
  -o -name "*.md" -o -name "*.toml" \
  -o -name "*.js" -o -name "*.ts" \
  -o -name "*.py" -o -name "*.rb" \
  -o -name "Makefile" -o -name "*.mk" \
  -o -name "Brewfile*" \
  -o -name ".gitignore" -o -name ".gitattributes" \) \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/.cache/*" 2>/dev/null)

TOTAL_FILES=$(echo "$FILES" | wc -l | xargs)

print_section "Processing $TOTAL_FILES files..."
printf '\n'

# Function to fix a file
fix_file() {
  local file="$1"
  local fixed=0

  # Check if file exists and is not empty
  [[ ! -f "$file" ]] && return 1
  [[ ! -s "$file" ]] && return 1

  # Skip binary files
  if file "$file" | grep -q "text\|empty"; then
    # Fix line endings (CRLF -> LF)
    if file "$file" | grep -q "CRLF"; then
      dos2unix "$file" 2>/dev/null || sed -i '' 's/\r$//' "$file"
      fixed=1
    fi

    # Trim trailing whitespace (except for markdown and txt)
    if [[ ! "$file" =~ \.(md|txt)$ ]]; then
      if grep -q '[[:space:]]$' "$file" 2>/dev/null; then
        sed -i '' 's/[[:space:]]*$//' "$file"
        fixed=1
      fi
    fi

    # Ensure final newline
    if [[ -s "$file" ]] && [[ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]]; then
      # Don't add newline to lock files
      if [[ ! "$file" =~ (yarn\.lock|pnpm-lock\.yaml|package-lock\.json)$ ]]; then
        echo "" >> "$file"
        fixed=1
      fi
    fi

    # Return 0 only when this file was modified.
    if [[ $fixed -eq 1 ]]; then
      return 0
    fi

    return 1
  fi

  return 1
}

# Process each file
while IFS= read -r file; do
  if fix_file "$file"; then
    FIXED_FILES=$((FIXED_FILES + 1))
    printf "  "
    print_success "$(basename "$file")"
  fi
done <<< "$FILES"


# Biome formatting for JS/TS/JSON
if command -v biome &>/dev/null; then
  printf '\n'
  print_section "Running Biome on JS/TS/JSON files..."
  printf '\n'

  # Run biome check with --write to format and fix
  BIOME_OUTPUT=$(biome check --write "$DOTFILES" 2>&1 || true)
  BIOME_FIXED=$(printf '%s\n' "$BIOME_OUTPUT" | awk '/Fixed/{count++} END{print count+0}')

  if [[ $BIOME_FIXED -gt 0 ]]; then
    print_warning "$BIOME_FIXED files formatted by Biome"
  else
    print_success "All files already formatted"
  fi
else
  printf '\n'
  print_warning "Biome not installed - skipping JS/TS/JSON formatting"
  print_dim "Install with: brew install biome"
fi

printf '\n'
print_section "Summary:"

if [[ $FIXED_FILES -gt 0 ]] || [[ ${BIOME_FIXED:-0} -gt 0 ]]; then
  print_warning "$(( FIXED_FILES + ${BIOME_FIXED:-0} )) files were modified"
  if [[ $FIXED_FILES -gt 0 ]]; then
    print_bullet "Fixed line endings (CRLF → LF)"
    print_bullet "Trimmed trailing whitespace"
    print_bullet "Added final newlines"
  fi
  if [[ ${BIOME_FIXED:-0} -gt 0 ]]; then
    print_bullet "Formatted JS/TS/JSON with Biome"
  fi
  printf '\n'
  print_info "Review changes with: git diff"
else
  print_success "All files already formatted correctly!"
fi

printf '\n'
print_dim "Note: Indentation is handled by your editor automatically"
print_dim "Open any file to see EditorConfig formatting in action"
