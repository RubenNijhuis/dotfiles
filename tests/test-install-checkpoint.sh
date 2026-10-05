#!/usr/bin/env bash
# Verify install checkpoint/resume logic remains idempotent.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"

test_home="$(mktemp -d)"
trap 'rmdir "$test_home"' EXIT

# Preview and help must not create logs, configuration, or Developer folders.
for mode in --help --dry-run --self-test-checkpoint; do
  HOME="$test_home" DOTFILES_DEVELOPER_ROOT="$test_home/Developer" \
    bash "$ROOT_DIR/install.sh" "$mode" --yes --without-ssh --without-gpg >/dev/null
  if [[ -n "$(ls -A "$test_home")" ]]; then
    print_error "installer $mode changed the isolated home"
    exit 1
  fi
done

# Shared helpers must agree with the managed shell's canonical file locations.
HOME="$test_home" DOTFILES_FILES_ROOT="$test_home/Files" \
  bash -c '
    unset DOTFILES_OBSIDIAN_VAULT_PATH DOTFILES_SCREENSHOTS_PATH
    source "$1/lib/env.sh"
    dotfiles_load_env "$1"
    [[ "$DOTFILES_OBSIDIAN_VAULT_PATH" == "$DOTFILES_FILES_ROOT" ]]
    [[ "$DOTFILES_SCREENSHOTS_PATH" == "$DOTFILES_FILES_ROOT/00 Inbox/Screenshots" ]]
  ' _ "$ROOT_DIR"

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
