#!/usr/bin/env bash
# Render the command-center help surfaces by parsing the Makefile.
# Single source of truth — Makefile sections (# ── Foo ──) become headers,
# `target: ## description` lines become commands. Add a target to the
# Makefile, get it documented in help automatically.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [main|setup|brew|launchd|test]

Render the dotfiles command-center help screens. Content is parsed from
$DOTFILES/Makefile; edit target descriptions there.

Sections:
  main     — all targets grouped by Makefile section
  setup    — bootstrap and identity commands
  brew     — Brewfile sync/audit and spicetify
  launchd  — automation lifecycle
  test     — verification and contract checks
EOF
}

show_help_if_requested usage "$@"

section="${1:-main}"
MAKEFILE="$DOTFILES/Makefile"

# Print a single command row with consistent formatting.
print_command() {
  printf "  \033[36m%-22s\033[0m %s\n" "$1" "$2"
}

# Render a Makefile section by header keyword (case-insensitive substring).
# A section header looks like: # ── Foo Bar ───────────
# We collect every `target: ## description` line until the next header.
render_section() {
  local header_match="$1"
  awk -v match_pat="$header_match" '
    BEGIN { in_section = 0 }
    /^# ── / {
      if (in_section) { exit }
      hdr = $0; sub(/^# ── */, "", hdr); sub(/ *─.*$/, "", hdr)
      if (tolower(hdr) ~ tolower(match_pat)) {
        printf "\n\033[1m%s\033[0m\n", hdr
        in_section = 1
      }
      next
    }
    in_section && /^[a-zA-Z][a-zA-Z0-9_-]*:.*## / {
      target = $0; sub(/:.*$/, "", target)
      desc = $0; sub(/^[^#]*## */, "", desc)
      printf "  \033[36m%-22s\033[0m %s\n", target, desc
    }
  ' "$MAKEFILE"
}

render_main() {
  printf "\n\033[1mDotfiles Command Center\033[0m\n"
  printf "%s\n" "Run \`make <target>\` for any command below. Sourced from the Makefile."
  awk '
    /^# ── / {
      hdr = $0; sub(/^# ── */, "", hdr); sub(/ *─.*$/, "", hdr)
      current_section = hdr
      section_printed = 0
      next
    }
    /^[a-zA-Z][a-zA-Z0-9_-]*:.*## / {
      if (!section_printed && current_section != "") {
        printf "\n\033[1m%s\033[0m\n", current_section
        section_printed = 1
      }
      target = $0; sub(/:.*$/, "", target)
      desc = $0; sub(/^[^#]*## */, "", desc)
      printf "  \033[36m%-22s\033[0m %s\n", target, desc
    }
  ' "$MAKEFILE"
  printf "\n\033[2mSuggested flow: make doctor -> make update\033[0m\n"
}

case "$section" in
  main)    render_main ;;
  setup)   render_section "setup" ;;
  brew)    render_section "brew" ;;
  launchd) render_section "launchd" ;;
  test)    render_section "testing" ;;
  *)
    printf 'Unknown help section: %s\n' "$section" >&2
    usage
    exit 1
    ;;
esac
