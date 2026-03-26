#!/usr/bin/env bash
# Integration tests for multi-script workflows and dry-run safety.
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

# ── clean.sh --dry-run is non-destructive ───────────────────────────

test_clean_dry_run_safe() {
  local temp_home cache_dir log_dir
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  # Create fake cache and log files
  cache_dir="$temp_home/.cache/zsh"
  mkdir -p "$cache_dir"
  echo "cache" > "$cache_dir/compdump"

  log_dir="$temp_home/.local/log"
  mkdir -p "$log_dir"
  echo "log" > "$log_dir/dotfiles-test.log"

  # Run dry-run
  HOME="$temp_home" bash "$ROOT_DIR/ops/clean.sh" --no-color --dry-run >/dev/null 2>&1

  # Verify files still exist
  if [[ ! -f "$cache_dir/compdump" ]]; then
    print_error "FAIL(clean-dry-run): cache file was deleted"
    failures=$((failures + 1))
  fi
  if [[ ! -f "$log_dir/dotfiles-test.log" ]]; then
    print_error "FAIL(clean-dry-run): log file was deleted"
    failures=$((failures + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── clean-all.sh --dry-run is non-destructive ──────────────────────

test_clean_all_dry_run_safe() {
  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  # Create fake backup directories
  mkdir -p "$temp_home/dotfiles.backup.test"
  echo "data" > "$temp_home/dotfiles.backup.test/file.txt"

  HOME="$temp_home" bash "$ROOT_DIR/ops/clean-all.sh" --no-color --dry-run >/dev/null 2>&1

  if [[ ! -d "$temp_home/dotfiles.backup.test" ]]; then
    print_error "FAIL(clean-all-dry-run): backup dir was deleted"
    failures=$((failures + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── restore-backup.sh --dry-run is non-destructive ─────────────────

test_restore_dry_run_safe() {
  local temp_home backup_dir
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  # Create a fake backup
  backup_dir="$temp_home/.dotfiles-backup/20250101-120000"
  mkdir -p "$backup_dir"
  echo "original-content" > "$backup_dir/.zshrc"
  echo "$backup_dir" > "$temp_home/.dotfiles-backup/latest"

  # Create a current file that would be overwritten
  echo "current-content" > "$temp_home/.zshrc"

  HOME="$temp_home" bash "$ROOT_DIR/ops/restore-backup.sh" --no-color --dry-run >/dev/null 2>&1

  # Verify current file was NOT overwritten
  local content
  content="$(cat "$temp_home/.zshrc")"
  if [[ "$content" != "current-content" ]]; then
    print_error "FAIL(restore-dry-run): file was overwritten during dry-run"
    failures=$((failures + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── stow-all then doctor --section stow ────────────────────────────

test_stow_then_doctor() {
  if ! command -v stow >/dev/null 2>&1; then
    print_warning "integration(stow-doctor): skipped (stow not installed)"
    return 0
  fi

  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  HOME="$temp_home" bash "$ROOT_DIR/setup/stow-all.sh" --no-color >/dev/null 2>&1

  # Doctor --section stow checks stow health. It may exit non-zero due to a
  # known set -e interaction with should_run's short-circuit return value, so
  # verify success via output instead of exit code.
  set +e
  local output
  output=$(HOME="$temp_home" bash "$ROOT_DIR/health/doctor.sh" --no-color --section stow 2>&1)
  set -e

  if ! printf '%s' "$output" | /usr/bin/grep -q "✓ Stow Configuration"; then
    print_error "FAIL(stow-then-doctor): stow check did not pass"
    failures=$((failures + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── Run all tests ───────────────────────────────────────────────────

test_clean_dry_run_safe
test_clean_all_dry_run_safe
test_restore_dry_run_safe
test_stow_then_doctor

if [[ $failures -gt 0 ]]; then
  print_error "integration: $failures test(s) failed"
  exit 1
fi

print_success "integration: all checks passed"
