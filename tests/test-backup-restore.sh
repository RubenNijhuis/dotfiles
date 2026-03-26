#!/usr/bin/env bash
# Tests for backup-dotfiles.sh behavior with isolated temp directories.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"

failures=0

# ── Backup creates directory and latest pointer ─────────────────────

test_backup_creates_files() {
  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  # Create real files (not symlinks) that backup-dotfiles.sh looks for
  echo "zshrc-content" > "$temp_home/.zshrc"
  echo "gitconfig-content" > "$temp_home/.gitconfig"

  HOME="$temp_home" bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null 2>&1

  # Verify latest pointer exists
  if [[ ! -f "$temp_home/.dotfiles-backup/latest" ]]; then
    print_error "FAIL(backup-creates): latest pointer not created"
    failures=$((failures + 1))
    trap - RETURN
    rm -rf "$temp_home"
    return
  fi

  # Verify backup directory exists and contains files
  local backup_dir
  backup_dir="$(cat "$temp_home/.dotfiles-backup/latest")"
  if [[ ! -d "$backup_dir" ]]; then
    print_error "FAIL(backup-creates): backup directory does not exist"
    failures=$((failures + 1))
    trap - RETURN
    rm -rf "$temp_home"
    return
  fi

  if [[ ! -f "$backup_dir/.zshrc" ]]; then
    print_error "FAIL(backup-creates): .zshrc not in backup"
    failures=$((failures + 1))
  fi

  if [[ ! -f "$backup_dir/.gitconfig" ]]; then
    print_error "FAIL(backup-creates): .gitconfig not in backup"
    failures=$((failures + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── Backup skips symlinks ───────────────────────────────────────────

test_backup_skips_symlinks() {
  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  # Create a real file and a symlink
  echo "real-file" > "$temp_home/.gitconfig"
  ln -s /dev/null "$temp_home/.zshrc"

  HOME="$temp_home" bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null 2>&1

  local backup_dir
  backup_dir="$(cat "$temp_home/.dotfiles-backup/latest")"

  # .gitconfig should be backed up (real file)
  if [[ ! -f "$backup_dir/.gitconfig" ]]; then
    print_error "FAIL(backup-skips-symlinks): real file not backed up"
    failures=$((failures + 1))
  fi

  # .zshrc should NOT be backed up (symlink)
  if [[ -f "$backup_dir/.zshrc" ]]; then
    print_error "FAIL(backup-skips-symlinks): symlink was backed up"
    failures=$((failures + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── Backup on empty home (no files to backup) ──────────────────────

test_backup_empty_home() {
  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  HOME="$temp_home" bash "$ROOT_DIR/ops/backup-dotfiles.sh" --no-color >/dev/null 2>&1

  # Should still create latest pointer
  if [[ ! -f "$temp_home/.dotfiles-backup/latest" ]]; then
    print_error "FAIL(backup-empty): latest pointer not created on empty home"
    failures=$((failures + 1))
  fi

  trap - RETURN
  rm -rf "$temp_home"
}

# ── Run all tests ───────────────────────────────────────────────────

test_backup_creates_files
test_backup_skips_symlinks
test_backup_empty_home

if [[ $failures -gt 0 ]]; then
  print_error "backup-restore: $failures test(s) failed"
  exit 1
fi

print_success "backup-restore: all checks passed"
