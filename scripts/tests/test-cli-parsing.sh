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

assert_exit 0 "bash '$ROOT_DIR/scripts/health/doctor.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/health/doctor.sh' --section nope"
assert_exit 0 "bash '$ROOT_DIR/scripts/automation/launchd-manager.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/automation/launchd-manager.sh' nope"
assert_exit 0 "bash '$ROOT_DIR/scripts/migration/migrate-developer-structure.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/migration/migrate-developer-structure.sh' --dry-run --complete"
assert_exit 0 "bash '$ROOT_DIR/scripts/backup/restore-backup.sh' --help"
assert_exit 0 "bash '$ROOT_DIR/scripts/maintenance/sync-brew.sh' --help"
assert_exit 0 "bash '$ROOT_DIR/scripts/bootstrap/stow-report.sh' --help"
assert_exit 0 "bash '$ROOT_DIR/scripts/automation/startup-ai-services.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/automation/startup-ai-services.sh' --policy invalid"
assert_exit 0 "bash '$ROOT_DIR/scripts/docs/generate-cli-reference.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/docs/generate-cli-reference.sh' --wat"
assert_exit 0 "bash '$ROOT_DIR/scripts/bootstrap/bootstrap-verify.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/scripts/bootstrap/bootstrap-verify.sh' --profile nope --skip-doctor"
assert_exit 0 "bash '$ROOT_DIR/install.sh' --help"
assert_exit 1 "bash '$ROOT_DIR/install.sh' --from-step 99"

echo "cli-parsing: all checks passed"
