#!/usr/bin/env bash
# Verify install checkpoint/resume logic remains idempotent.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/output.sh" "$@"

output=$(bash "$ROOT_DIR/install.sh" --self-test-checkpoint 2>&1)
code=$?

if [[ $code -ne 0 ]]; then
  print_error "install checkpoint self-test exited with $code"
  echo "$output"
  exit 1
fi

if ! echo "$output" | grep -q "Checkpoint self-test passed"; then
  print_error "expected success marker in checkpoint self-test output"
  echo "$output"
  exit 1
fi

print_success "install-checkpoint: passed"
