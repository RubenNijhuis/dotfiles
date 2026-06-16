#!/usr/bin/env bash
# Run all script behavior tests concurrently, buffering each test's output
# and replaying it in deterministic order. Exits non-zero if any test fails.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/parallel.sh
source "$SCRIPT_DIR/../lib/parallel.sh"

TESTS=(
  test-idempotency.sh
  test-cli-contract.sh
  test-cli-parsing.sh
  test-install-checkpoint.sh
  test-error-handling.sh
  test-backup-restore.sh
  test-integration.sh
)

TMP="$(parallel_tmpdir tests)"
trap 'rm -rf "$TMP"' EXIT

for t in "${TESTS[@]}"; do
  parallel_spawn "$TMP" "$t" bash "$SCRIPT_DIR/$t"
done
parallel_wait

parallel_replay "$TMP" "${TESTS[@]}"

FAILED=0
for t in "${TESTS[@]}"; do
  rc="$(parallel_rc "$TMP" "$t")"
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
