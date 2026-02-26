#!/usr/bin/env bash
# Guard against nounset issues: arrays must be initialized when declared.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/output.sh" "$@"

if command -v rg >/dev/null 2>&1; then
  violations=$(rg -n '^declare -a [A-Za-z_][A-Za-z0-9_]*\s*$' "$ROOT_DIR/scripts" \
    -g '!scripts/tests/*' -g '!scripts/lib/*' || true)
else
  violations=$(find "$ROOT_DIR/scripts" -type f -name '*.sh' \
    ! -path "$ROOT_DIR/scripts/tests/*" \
    ! -path "$ROOT_DIR/scripts/lib/*" \
    -print0 | xargs -0 grep -nE '^declare -a [A-Za-z_][A-Za-z0-9_]*[[:space:]]*$' || true)
fi

if [[ -n "$violations" ]]; then
  print_error "uninitialized array declarations found (use declare -a name=())"
  echo "$violations"
  exit 1
fi

print_success "array-init: all array declarations are initialized"
