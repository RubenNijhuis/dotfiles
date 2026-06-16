#!/usr/bin/env bash
# Run all script behavior tests concurrently, buffering each test's output
# and replaying it in deterministic order. Exits non-zero if any test fails.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TESTS=(
  test-idempotency.sh
  test-cli-contract.sh
  test-cli-parsing.sh
  test-install-checkpoint.sh
  test-error-handling.sh
  test-backup-restore.sh
  test-integration.sh
)

TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tests.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

for t in "${TESTS[@]}"; do
  (
    if bash "$SCRIPT_DIR/$t" >"$TMP/$t.out" 2>&1; then
      printf '0\n' > "$TMP/$t.rc"
    else
      printf '%s\n' "$?" > "$TMP/$t.rc"
    fi
  ) &
done
wait

FAILED=0
for t in "${TESTS[@]}"; do
  cat "$TMP/$t.out"
  rc="$(cat "$TMP/$t.rc" 2>/dev/null || echo 1)"
  if [[ "$rc" != "0" ]]; then
    printf '  \033[31m✗\033[0m %s exit=%s\n' "$t" "$rc"
    FAILED=$((FAILED + 1))
  fi
done

if [[ $FAILED -gt 0 ]]; then
  printf '\n  \033[31m✗\033[0m %d test file(s) failed\n' "$FAILED"
  exit 1
fi
printf '  \033[32m✓\033[0m Script tests passed\n'
