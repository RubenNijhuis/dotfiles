#!/usr/bin/env bash
# Error-path tests for scripts that handle missing deps, invalid inputs, and edge cases.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"

failures=0

assert_exit() {
  local label="$1" expected="$2"
  shift 2
  set +e
  "$@" >/dev/null 2>&1
  local actual=$?
  set -e
  if [[ "$actual" -ne "$expected" ]]; then
    print_error "FAIL($label): expected exit $expected, got $actual"
    failures=$((failures + 1))
  fi
}

assert_output_contains() {
  local label="$1" pattern="$2"
  shift 2
  set +e
  local output
  output=$("$@" 2>&1)
  set -e
  if ! printf '%s' "$output" | /usr/bin/grep -q "$pattern"; then
    print_error "FAIL($label): output missing '$pattern'"
    failures=$((failures + 1))
  fi
}

# ── restore-backup.sh with no backup ────────────────────────────────

test_restore_no_backup() {
  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  assert_exit "restore-no-backup" 1 \
    env HOME="$temp_home" bash "$ROOT_DIR/ops/restore-backup.sh" --no-color

  assert_output_contains "restore-no-backup-msg" "No backup found" \
    env HOME="$temp_home" bash "$ROOT_DIR/ops/restore-backup.sh" --no-color

  trap - RETURN
  rm -rf "$temp_home"
}

# ── restore-backup.sh with stale latest pointer ────────────────────

test_restore_stale_pointer() {
  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  mkdir -p "$temp_home/.dotfiles-backup"
  echo "/nonexistent/path" > "$temp_home/.dotfiles-backup/latest"

  assert_exit "restore-stale-pointer" 1 \
    env HOME="$temp_home" bash "$ROOT_DIR/ops/restore-backup.sh" --no-color

  assert_output_contains "restore-stale-pointer-msg" "Backup directory not found" \
    env HOME="$temp_home" bash "$ROOT_DIR/ops/restore-backup.sh" --no-color

  trap - RETURN
  rm -rf "$temp_home"
}

# ── clean.sh on empty HOME ──────────────────────────────────────────

test_clean_empty_home() {
  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  assert_exit "clean-empty-home" 0 \
    env HOME="$temp_home" bash "$ROOT_DIR/ops/clean.sh" --no-color

  trap - RETURN
  rm -rf "$temp_home"
}

# ── validate_launchd.py with empty directory ────────────────────────

test_validate_launchd_empty_dir() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  assert_exit "validate-launchd-empty" 1 \
    python3 "$ROOT_DIR/lib/validate_launchd.py" "$temp_dir"

  trap - RETURN
  rm -rf "$temp_dir"
}

# ── validate_launchd.py with malformed plist ────────────────────────

test_validate_launchd_malformed() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  echo "this is not valid xml" > "$temp_dir/com.user.test.plist"

  assert_exit "validate-launchd-malformed" 1 \
    python3 "$ROOT_DIR/lib/validate_launchd.py" "$temp_dir"

  trap - RETURN
  rm -rf "$temp_dir"
}

# ── Run all tests ───────────────────────────────────────────────────

test_restore_no_backup
test_restore_stale_pointer
test_clean_empty_home
test_validate_launchd_empty_dir
test_validate_launchd_malformed

if [[ $failures -gt 0 ]]; then
  print_error "error-handling: $failures test(s) failed"
  exit 1
fi

print_success "error-handling: all checks passed"
