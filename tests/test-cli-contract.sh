#!/usr/bin/env bash
# Enforce CLI contract for operational scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"

help_fail=0
unknown_fail=0

while IFS= read -r script; do
  name="${script##*/}"

  # Skip scripts marked as launchd-internal (no CLI contract required)
  if grep -q '^# SCRIPT_VISIBILITY: launchd-internal' "$script"; then
    continue
  fi

  if ! bash "$script" --help >/dev/null 2>&1; then
    print_error "FAIL(help): $name"
    help_fail=$((help_fail + 1))
  fi

  set +e
  output=$(bash "$script" --__invalid__ 2>&1)
  code=$?
  set -e

  if [[ $code -eq 0 ]]; then
    print_error "FAIL(unknown-exit): $name returned 0"
    unknown_fail=$((unknown_fail + 1))
    continue
  fi

  if ! printf '%s' "$output" | grep -Eq 'Usage:|usage:'; then
    print_error "FAIL(unknown-usage): $name missing usage output"
    unknown_fail=$((unknown_fail + 1))
  fi

done < <(
  find "$ROOT_DIR/setup" "$ROOT_DIR/ops" "$ROOT_DIR/health" -type f -name '*.sh' \
    -not -path "$ROOT_DIR/health/checks/*" | sort
)

if [[ $help_fail -gt 0 || $unknown_fail -gt 0 ]]; then
  print_error "cli-contract: failed (help=$help_fail unknown=$unknown_fail)"
  exit 1
fi

print_success "cli-contract: all checks passed"
