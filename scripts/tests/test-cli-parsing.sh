#!/usr/bin/env bash
# Validate parser behavior for key scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

assert_exit() {
  local expected="$1"
  local cmd="$2"
  local output

  set +e
  output=$(eval "$cmd" 2>&1)
  local code=$?
  set -e

  if [[ "$code" -ne "$expected" ]]; then
    echo "FAIL: expected exit $expected, got $code for: $cmd"
    echo "$output"
    exit 1
  fi
}

assert_exit 0 "bash '$ROOT_DIR/scripts/doctor.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/doctor.sh' --section nope"
assert_exit 0 "bash '$ROOT_DIR/scripts/launchd-manager.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/launchd-manager.sh' nope"
assert_exit 0 "bash '$ROOT_DIR/scripts/migrate-developer-structure.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/migrate-developer-structure.sh' --dry-run --complete"
assert_exit 0 "bash '$ROOT_DIR/scripts/restore-backup.sh' --help"
assert_exit 0 "bash '$ROOT_DIR/scripts/sync-brew.sh' --help"
assert_exit 0 "bash '$ROOT_DIR/scripts/stow-report.sh' --help"
assert_exit 0 "bash '$ROOT_DIR/install.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/install.sh' --from-step 99"

echo "cli-parsing: all checks passed"
