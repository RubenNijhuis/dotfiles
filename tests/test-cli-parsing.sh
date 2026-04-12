#!/usr/bin/env bash
# Validate parser behavior for key scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"
source "$ROOT_DIR/lib/test-helpers.sh"

assert_exit "doctor-help" 0 bash "$ROOT_DIR/health/doctor.sh" --help
assert_exit "doctor-full-section" 0 bash "$ROOT_DIR/health/doctor.sh" --no-color --full --section stow
assert_exit "doctor-bad-section" 1 bash "$ROOT_DIR/health/doctor.sh" --section nope
assert_exit "profile-list-help" 0 bash "$ROOT_DIR/ops/profile/list.sh" --help
assert_exit "profile-show-help" 0 bash "$ROOT_DIR/ops/profile/show.sh" --help
assert_exit "profile-set-bad-arg" 1 bash "$ROOT_DIR/ops/profile/set.sh" --bogus
assert_exit "launchd-help" 0 bash "$ROOT_DIR/ops/automation/launchd-manager.sh" --help
assert_exit "launchd-bad-cmd" 1 bash "$ROOT_DIR/ops/automation/launchd-manager.sh" nope
assert_exit "restore-help" 0 bash "$ROOT_DIR/ops/restore-backup.sh" --help
assert_exit "sync-brew-help" 0 bash "$ROOT_DIR/ops/sync-brew.sh" --help
assert_exit "stow-report-help" 0 bash "$ROOT_DIR/setup/stow-report.sh" --help
assert_exit "cli-ref-help" 0 bash "$ROOT_DIR/ops/generate-cli-reference.sh" --help
assert_exit "cli-ref-bad-flag" 1 bash "$ROOT_DIR/ops/generate-cli-reference.sh" --wat
assert_exit "bootstrap-help" 0 bash "$ROOT_DIR/setup/bootstrap-verify.sh" --help
assert_exit "bootstrap-bad-flag" 1 bash "$ROOT_DIR/setup/bootstrap-verify.sh" --bogus
assert_exit "install-help" 0 bash "$ROOT_DIR/install.sh" --help
assert_exit "install-bad-step" 1 bash "$ROOT_DIR/install.sh" --from-step 99

test_summary "cli-parsing"
