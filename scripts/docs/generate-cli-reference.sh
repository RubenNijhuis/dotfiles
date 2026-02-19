#!/usr/bin/env bash
# Generate canonical CLI help reference for dotfiles scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

OUTPUT_FILE="$DOTFILES/docs/reference/cli.md"
CHECK_MODE=false

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--check]

Generate docs/reference/cli.md from --help output.

Options:
  --check    Exit non-zero if generated output differs from committed file.
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --check)
        CHECK_MODE=true
        shift
        ;;
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

append_help_block() {
  local title="$1"
  local cmd="$2"

  printf "## \`%s\`\n\n" "$title" >> "$TMP_FILE"
  printf '```text\n' >> "$TMP_FILE"
  if ! eval "$cmd" >> "$TMP_FILE" 2>&1; then
    printf '[help command failed]\n' >> "$TMP_FILE"
  fi
  printf '```\n\n' >> "$TMP_FILE"
}

main() {
  parse_args "$@"

  mkdir -p "$(dirname "$OUTPUT_FILE")"
  TMP_FILE="$(mktemp)"

  {
    echo '# CLI Reference'
    echo ''
    echo "Generated from live \`--help\` output. Do not edit manually; run \`make docs-generate\`."
    echo ''
  } > "$TMP_FILE"

  append_help_block "install.sh" "bash '$DOTFILES/install.sh' --help"

  while IFS= read -r script; do
    script_name="${script#"$DOTFILES"/}"
    append_help_block "$script_name" "bash '$script' --help"
  done < <(
    find "$DOTFILES/scripts" -type f -name '*.sh' \
      -not -path "$DOTFILES/scripts/lib/*" \
      -not -path "$DOTFILES/scripts/tests/*" \
      -not -path "$DOTFILES/scripts/automation/launchd/*" \
      -not -path "$DOTFILES/scripts/health/checks/*" | sort
  )

  if $CHECK_MODE; then
    if cmp -s "$TMP_FILE" "$OUTPUT_FILE"; then
      print_success "CLI reference is up to date"
      rm -f "$TMP_FILE"
      exit 0
    fi

    print_error "CLI reference is stale: run make docs-generate"
    diff -u "$OUTPUT_FILE" "$TMP_FILE" || true
    rm -f "$TMP_FILE"
    exit 1
  fi

  mv "$TMP_FILE" "$OUTPUT_FILE"
  print_success "Generated $OUTPUT_FILE"
}

main "$@"
