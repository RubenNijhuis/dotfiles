#!/usr/bin/env bash
# Verify install checkpoint/resume logic remains idempotent.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

output=$(bash "$ROOT_DIR/install.sh" --self-test-checkpoint 2>&1)
code=$?

if [[ $code -ne 0 ]]; then
  echo "FAIL: install checkpoint self-test exited with $code"
  echo "$output"
  exit 1
fi

if ! echo "$output" | grep -q "Checkpoint self-test passed"; then
  echo "FAIL: expected success marker in checkpoint self-test output"
  echo "$output"
  exit 1
fi

echo "install-checkpoint: passed"
