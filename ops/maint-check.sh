#!/usr/bin/env bash
# Run maintenance validation checks in parallel.
# Buffers each step's output and replays it in fixed order; exits non-zero
# if any step fails.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/parallel.sh
source "$DOTFILES/lib/parallel.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Run all maintenance validation checks (lint, tests, contracts, docs, brew,
vscode-parity) in parallel and exit non-zero if any check fails.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --no-color) ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; usage >&2; exit 1 ;;
  esac
done

# Each entry pairs a label with a command (label|cmd). Order defines the
# replay order on failure summaries. Kept as a flat list to stay
# bash 3.2-compatible (macOS stock + CI).
STEPS=(
  "lint-shell|bash $DOTFILES/ops/lint-shell.sh"
  "test-scripts|bash $DOTFILES/tests/run-parallel.sh"
  "launchd-check|bash $DOTFILES/health/check-launchd-contracts.sh"
  "docs-regen|bash $DOTFILES/ops/generate-cli-reference.sh"
  "vscode-parity|bash $DOTFILES/health/check-vscode-parity.sh --check"
  "brew-audit|bash $DOTFILES/ops/brew-audit.sh"
)

TMP="$(parallel_tmpdir maint)"
trap 'rm -rf "$TMP"' EXIT

for entry in "${STEPS[@]}"; do
  label="${entry%%|*}"
  cmd="${entry#*|}"
  parallel_spawn "$TMP" "$label" bash -c "$cmd"
done
parallel_wait

printf '\n=== Maintenance Check ===\n\n'
FAILED=0
for entry in "${STEPS[@]}"; do
  label="${entry%%|*}"
  rc="$(parallel_rc "$TMP" "$label")"
  if [[ "$rc" == "0" ]]; then
    printf '  \033[32m✓\033[0m %s\n' "$label"
  else
    printf '  \033[31m✗\033[0m %s (exit=%s)\n' "$label" "$rc"
    printf '    --- %s output ---\n' "$label"
    sed 's/^/    /' "$TMP/$label.out"
    FAILED=$((FAILED + 1))
  fi
done

printf '\n'
if [[ $FAILED -gt 0 ]]; then
  printf '\033[31m✗\033[0m %d check(s) failed\n' "$FAILED"
  exit 1
fi
printf '\033[32m✓\033[0m All maintenance checks passed\n'
