#!/usr/bin/env bash
# Smoke test: ensure every operational script supports --help.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
source "$ROOT_DIR/scripts/lib/output.sh" "$@"

passed=0
failed=0

while IFS= read -r script; do
  if bash "$script" --help >/dev/null 2>&1; then
    passed=$((passed + 1))
  else
    print_error "--help failed for $script"
    failed=$((failed + 1))
  fi
done < <(
  find "$SCRIPTS_DIR" -type f -name '*.sh' \
    -not -path "$SCRIPTS_DIR/lib/*" \
    -not -path "$SCRIPTS_DIR/tests/*" \
    -not -path "$SCRIPTS_DIR/automation/launchd/*" \
    -not -path "$SCRIPTS_DIR/health/checks/*" | sort
)

if [[ $failed -eq 0 ]]; then
  print_success "help-smoke: $passed passed, $failed failed"
else
  print_error "help-smoke: $passed passed, $failed failed"
fi

if [[ $failed -gt 0 ]]; then
  exit 1
fi
