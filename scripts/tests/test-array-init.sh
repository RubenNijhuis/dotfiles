#!/usr/bin/env bash
# Guard against nounset issues: arrays must be initialized when declared.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

violations=$(rg -n '^declare -a [A-Za-z_][A-Za-z0-9_]*\s*$' "$ROOT_DIR/scripts" \
  -g '!scripts/tests/*' -g '!scripts/lib/*' || true)

if [[ -n "$violations" ]]; then
  echo "FAIL: uninitialized array declarations found (use declare -a name=())"
  echo "$violations"
  exit 1
fi

echo "array-init: all array declarations are initialized"
