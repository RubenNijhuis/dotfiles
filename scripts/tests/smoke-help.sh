#!/usr/bin/env bash
# Smoke test: ensure every operational script supports --help.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"

passed=0
failed=0

while IFS= read -r script; do
  if bash "$script" --help >/dev/null 2>&1; then
    passed=$((passed + 1))
  else
    echo "FAIL: --help failed for $script"
    failed=$((failed + 1))
  fi
done < <(
  find "$SCRIPTS_DIR" -type f -name '*.sh' \
    -not -path "$SCRIPTS_DIR/lib/*" \
    -not -path "$SCRIPTS_DIR/tests/*" \
    -not -path "$SCRIPTS_DIR/health/checks/*" | sort
)

echo "help-smoke: $passed passed, $failed failed"

if [[ $failed -gt 0 ]]; then
  exit 1
fi
