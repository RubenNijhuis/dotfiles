#!/usr/bin/env bash
# Integration tests for multi-script workflows and dry-run safety.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"
source "$ROOT_DIR/lib/test-helpers.sh"

# ── clean.sh --dry-run is non-destructive ───────────────────────────

test_clean_dry_run_safe() {
  local temp_home cache_dir log_dir
  temp_home="$(make_temp_home)"
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
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi
  if [[ ! -f "$log_dir/dotfiles-test.log" ]]; then
    print_error "FAIL(clean-dry-run): log file was deleted"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── restore-backup.sh --dry-run is non-destructive ─────────────────

test_restore_dry_run_safe() {
  local temp_home backup_dir
  temp_home="$(make_temp_home)"
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
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}


# ── ops-status uses the doctor task log, not the launchd wrapper log ───────

test_ops_status_uses_doctor_task_log() {
  local temp_home temp_bin fake_launchctl output fixture_root
  temp_home="$(make_temp_home)"
  temp_bin="$(make_temp_home)"
  trap 'rm -rf "$temp_home" "$temp_bin"' RETURN

  mkdir -p "$temp_home/.local/log"
  cat > "$temp_home/.local/log/dotfiles-doctor.out.log" <<'EOF'
System Health Check
15/15 checks: 15 passed
EOF
  : > "$temp_home/.local/log/dotfiles-doctor-launchd.err.log"

  touch -t 202604120209 "$temp_home/.local/log/dotfiles-doctor.out.log"
  touch -t 202604101158 "$temp_home/.local/log/dotfiles-doctor-launchd.err.log"

  fake_launchctl="$temp_bin/launchctl"
  cat > "$fake_launchctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
case "$cmd" in
  print) exit 0 ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$fake_launchctl"

  # Select the doctor explicitly in a disposable repository. The real laptop
  # no longer enables a daily doctor merely to support this test.
  fixture_root="$temp_bin/repo"
  mkdir -p "$fixture_root/health" "$fixture_root/ops/automation" \
    "$fixture_root/lib" "$fixture_root/profiles"
  cp "$ROOT_DIR/health/doctor.sh" "$fixture_root/health/"
  cp "$ROOT_DIR/ops/automation/launchd-manager.sh" \
    "$ROOT_DIR/ops/automation/agents.manifest" "$fixture_root/ops/automation/"
  cp "$ROOT_DIR"/lib/*.sh "$fixture_root/lib/"
  printf '%s\n' 'DOTFILES_PROFILE_AUTOMATIONS="dotfiles-doctor"' \
    > "$fixture_root/profiles/personal-laptop.env"
  output=$(HOME="$temp_home" PATH="$temp_bin:$PATH" \
    bash "$fixture_root/health/doctor.sh" --automation --no-color 2>&1)

  if ! printf '%s' "$output" | /usr/bin/grep -q "dotfiles-doctor    \[OK\] loaded | out 2026-04-12 02:09"; then
    print_error "FAIL(ops-status-doctor-log): expected task log timestamp"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home" "$temp_bin"
}

# ── Run all tests ───────────────────────────────────────────────────

test_clean_dry_run_safe
test_restore_dry_run_safe
test_ops_status_uses_doctor_task_log

test_summary "integration"
