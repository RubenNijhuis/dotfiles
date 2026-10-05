#!/usr/bin/env bash
# Tests for backup-dotfiles.sh behavior with isolated temp directories.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"
source "$ROOT_DIR/lib/test-helpers.sh"

# ── Backup creates directory and latest pointer ─────────────────────

test_backup_creates_files() {
  local temp_home
  temp_home="$(make_temp_home)"
  trap 'rm -rf "$temp_home"' RETURN

  # Create machine-specific files the script looks for
  mkdir -p "$temp_home/.ssh"
  echo "ssh-key-content" > "$temp_home/.ssh/id_ed25519_personal"
  mkdir -p "$temp_home/.config/shell"
  echo "local-config" > "$temp_home/.config/shell/local.sh"

  env HOME="$temp_home" DOTFILES_BACKUP_LOCAL_DIR="$temp_home/local" \
    bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null 2>&1

  # Verify latest pointer exists
  if [[ ! -f "$temp_home/.dotfiles-backup/latest" ]]; then
    print_error "FAIL(backup-creates): latest pointer not created"
    TEST_FAILURES=$((TEST_FAILURES + 1))
    trap - RETURN
    rm -rf "$temp_home"
    return
  fi

  # Verify backup directory exists and contains files
  local backup_dir
  backup_dir="$(cat "$temp_home/.dotfiles-backup/latest")"
  if [[ ! -d "$backup_dir" ]]; then
    print_error "FAIL(backup-creates): backup directory does not exist"
    TEST_FAILURES=$((TEST_FAILURES + 1))
    trap - RETURN
    rm -rf "$temp_home"
    return
  fi

  # SSH key should be backed up
  if ! find "$backup_dir" -name "id_ed25519_personal" -print -quit | grep -q .; then
    print_error "FAIL(backup-creates): SSH key not in backup"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  # local.sh should be backed up
  if [[ ! -f "$backup_dir/local.sh" ]]; then
    print_error "FAIL(backup-creates): local.sh not in backup"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── Backup skips symlinks ───────────────────────────────────────────

test_backup_skips_symlinks() {
  local temp_home
  temp_home="$(make_temp_home)"
  trap 'rm -rf "$temp_home"' RETURN

  # Create a real file and a symlink
  mkdir -p "$temp_home/.config/shell"
  echo "real-local" > "$temp_home/.config/shell/local.sh"
  mkdir -p "$temp_home/.gnupg"
  ln -s /dev/null "$temp_home/.gnupg/common.conf"

  env HOME="$temp_home" DOTFILES_BACKUP_LOCAL_DIR="$temp_home/local" \
    bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null 2>&1

  local backup_dir
  backup_dir="$(cat "$temp_home/.dotfiles-backup/latest")"

  # local.sh should be backed up (real file)
  if [[ ! -f "$backup_dir/local.sh" ]]; then
    print_error "FAIL(backup-skips-symlinks): real file not backed up"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  # common.conf should NOT be backed up (symlink)
  if [[ -f "$backup_dir/common.conf" ]]; then
    print_error "FAIL(backup-skips-symlinks): symlink was backed up"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── Backup on empty home (no files to backup) ──────────────────────

test_backup_empty_home() {
  local temp_home
  temp_home="$(make_temp_home)"
  trap 'rm -rf "$temp_home"' RETURN

  env HOME="$temp_home" DOTFILES_BACKUP_LOCAL_DIR="$temp_home/local" \
    bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null 2>&1

  # Should still create latest pointer
  if [[ ! -f "$temp_home/.dotfiles-backup/latest" ]]; then
    print_error "FAIL(backup-empty): latest pointer not created on empty home"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── Run all tests ───────────────────────────────────────────────────

test_backup_creates_files
test_backup_skips_symlinks
test_backup_empty_home

# Nested paths, public keys, permissions, unique runs, and non-destructive restore.
test_backup_roundtrip() (
  set -euo pipefail
  local temp_home backup_dir second_dir archive
  temp_home="$(make_temp_home)"
  # macOS mktemp commonly returns /var/...; /var itself is a symlink.
  temp_home="$(cd "$temp_home" && pwd -P)"
  trap 'rm -rf "$temp_home"' EXIT
  export HOME="$temp_home" DOTFILES_BACKUP_LOCAL_DIR="$temp_home/local"
  source "$ROOT_DIR/lib/common.sh"
  mkdir -p "$temp_home/.ssh/one" "$temp_home/.ssh/two" "$temp_home/local/deep"
  printf 'one' > "$temp_home/.ssh/one/config"
  printf 'two' > "$temp_home/.ssh/two/config"
  printf 'public' > "$temp_home/.ssh/key.pub"
  printf 'local' > "$temp_home/local/deep/config"
  ln -s "$temp_home/.ssh/one/config" "$temp_home/.ssh/ignored-link"
  bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null
  backup_dir="$(cat "$temp_home/.dotfiles-backup/latest")"
  [[ "$(cat "$backup_dir/.ssh/one/config")" == one ]]
  [[ "$(cat "$backup_dir/.ssh/two/config")" == two ]]
  [[ -f "$backup_dir/.ssh/key.pub" && ! -e "$backup_dir/.ssh/ignored-link" ]]
  [[ -f "$backup_dir/local/deep/config" ]]
  [[ "$(file_mode "$backup_dir")" == 700 ]]
  [[ "$(file_mode "$backup_dir/.ssh/key.pub")" == 600 ]]
  touch -t 202001010000 "$backup_dir"
  bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null
  second_dir="$(cat "$temp_home/.dotfiles-backup/latest")"
  [[ "$second_dir" != "$backup_dir" && -d "$backup_dir" ]]
  mkdir "$temp_home/.dotfiles-backup/20991231-incomplete"
  [[ "$(latest_rollback_dir)" == "$second_dir" ]]
  [[ "$(file_mtime_epoch "$second_dir")" =~ ^[0-9]+$ ]]
  printf 'changed' > "$temp_home/.ssh/one/config"
  bash "$ROOT_DIR/ops/restore-backup.sh" --dry-run --no-color >/dev/null
  [[ "$(cat "$temp_home/.ssh/one/config")" == changed ]]
  printf 'y\n' | bash "$ROOT_DIR/ops/restore-backup.sh" --no-color >/dev/null
  [[ "$(cat "$temp_home/.ssh/one/config")" == one ]]
  [[ "$(cat "$temp_home/local/deep/config")" == local ]]
  # An approved restore still cannot overwrite a Nix/symlink-owned path.
  ln -s "$temp_home/.ssh/one/config" "$temp_home/.ssh/key.pub.link"
  mv "$temp_home/.ssh/key.pub.link" "$temp_home/.ssh/key.pub"
  if printf 'y\n' | bash "$ROOT_DIR/ops/restore-backup.sh" --no-color >/dev/null 2>&1; then
    exit 1
  fi
  [[ -L "$temp_home/.ssh/key.pub" ]]
  archive="$temp_home/.dotfiles-backup/legacy.tar.gz"
  tar -czf "$archive" -C "$temp_home/.dotfiles-backup" "$(basename "$backup_dir")"
  printf '%s\n' "$archive" > "$temp_home/.dotfiles-backup/latest"
  if bash "$ROOT_DIR/ops/restore-backup.sh" --dry-run --no-color >/dev/null 2>&1; then
    exit 1
  fi
  [[ ! -d "$temp_home/.dotfiles-backup/legacy" ]]
)
assert_exit "backup-roundtrip" 0 test_backup_roundtrip

test_summary "backup-restore"
