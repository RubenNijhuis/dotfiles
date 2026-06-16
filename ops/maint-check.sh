#!/usr/bin/env bash
# Run maintenance validation checks in parallel.
# Buffers each step's output and replays it in fixed order; exits non-zero
# if any step fails.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# Steps: label|command
STEPS=(
  "lint-shell|bash $DOTFILES/ops/lint-shell.sh"
  "test-scripts|bash $DOTFILES/tests/run-parallel.sh"
  "launchd-check|bash $DOTFILES/health/check-launchd-contracts.sh"
  "docs-regen|bash $DOTFILES/ops/generate-cli-reference.sh"
  "vscode-parity|bash $DOTFILES/health/check-vscode-parity.sh --check"
  "brew-audit|bash $DOTFILES/ops/brew-audit.sh"
)

TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-maint.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

for entry in "${STEPS[@]}"; do
  label="${entry%%|*}"
  cmd="${entry#*|}"
  (
    if eval "$cmd" >"$TMP/$label.out" 2>&1; then
      printf '0\n' > "$TMP/$label.rc"
    else
      printf '%s\n' "$?" > "$TMP/$label.rc"
    fi
  ) &
done
wait

FAILED=0
printf '\n=== Maintenance Check ===\n\n'
for entry in "${STEPS[@]}"; do
  label="${entry%%|*}"
  rc="$(cat "$TMP/$label.rc" 2>/dev/null || echo 1)"
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
