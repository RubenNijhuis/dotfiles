#!/usr/bin/env bash
# Idempotency checks for high-risk operational scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"

fail() {
  print_error "$1"
  exit 1
}

test_chezmoi_apply_idempotent() {
  if ! command -v chezmoi >/dev/null 2>&1; then
    print_warning "idempotency(chezmoi): skipped (chezmoi not installed)"
    return 0
  fi

  local temp_home listing1 listing2
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  # Use an isolated HOME and source state — don't touch the real one.
  HOME="$temp_home" chezmoi apply --source "$ROOT_DIR/chezmoi" --destination "$temp_home" >/dev/null

  listing1="$(mktemp)"
  listing2="$(mktemp)"
  find "$temp_home" \( -type f -o -type l \) -print | sort > "$listing1"

  HOME="$temp_home" chezmoi apply --source "$ROOT_DIR/chezmoi" --destination "$temp_home" >/dev/null
  find "$temp_home" \( -type f -o -type l \) -print | sort > "$listing2"

  if ! diff -u "$listing1" "$listing2" >/dev/null; then
    diff -u "$listing1" "$listing2" || true
    fail "chezmoi apply changed file set on second run"
  fi

  rm -f "$listing1" "$listing2"
  trap - RETURN
  rm -rf "$temp_home"

  print_success "idempotency(chezmoi): passed"
}

test_launchd_manager_idempotent() {
  local temp_home temp_bin temp_state fake_launchctl manager plist hash1 hash2

  temp_home="$(mktemp -d)"
  temp_bin="$(mktemp -d)"
  temp_state="$(mktemp -d)"

  trap 'rm -rf "$temp_home" "$temp_bin" "$temp_state"' RETURN

  fake_launchctl="$temp_bin/launchctl"
  cat > "$fake_launchctl" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${FAKE_LAUNCHCTL_STATE_DIR:?}"
cmd="${1:-}"

label_from_plist() {
  local plist="$1"
  basename "$plist" .plist
}

case "$cmd" in
  print)
    target="${2:-}"
    label="${target##*/}"
    [[ -f "$STATE_DIR/$label.loaded" ]]
    ;;
  bootstrap|load)
    plist="${@: -1}"
    label="$(label_from_plist "$plist")"
    touch "$STATE_DIR/$label.loaded"
    ;;
  bootout|unload)
    last="${@: -1}"
    if [[ "$last" == *.plist ]]; then
      label="$(label_from_plist "$last")"
    else
      label="${last##*/}"
    fi
    rm -f "$STATE_DIR/$label.loaded"
    ;;
  *)
    exit 0
    ;;
esac
EOS
  chmod +x "$fake_launchctl"

  manager="$ROOT_DIR/ops/automation/launchd-manager.sh"

  HOME="$temp_home" PATH="$temp_bin:$PATH" FAKE_LAUNCHCTL_STATE_DIR="$temp_state" \
    bash "$manager" --no-color install dotfiles-backup >/dev/null

  plist="$temp_home/Library/LaunchAgents/com.user.dotfiles-backup.plist"
  [[ -f "$plist" ]] || fail "launchd-manager did not install plist"
  hash1=$(shasum -a 256 "$plist" | awk '{print $1}')

  HOME="$temp_home" PATH="$temp_bin:$PATH" FAKE_LAUNCHCTL_STATE_DIR="$temp_state" \
    bash "$manager" --no-color install dotfiles-backup >/dev/null

  hash2=$(shasum -a 256 "$plist" | awk '{print $1}')
  if [[ "$hash1" != "$hash2" ]]; then
    fail "launchd-manager install output changed across repeated install"
  fi

  HOME="$temp_home" PATH="$temp_bin:$PATH" FAKE_LAUNCHCTL_STATE_DIR="$temp_state" \
    bash "$manager" --no-color uninstall dotfiles-backup >/dev/null

  HOME="$temp_home" PATH="$temp_bin:$PATH" FAKE_LAUNCHCTL_STATE_DIR="$temp_state" \
    bash "$manager" --no-color uninstall dotfiles-backup >/dev/null

  trap - RETURN
  rm -rf "$temp_home" "$temp_bin" "$temp_state"

  print_success "idempotency(launchd-manager): passed"
}

test_chezmoi_source_files_are_regular() {
  # chezmoi materializes regular files (not symlinks) into $HOME — verify
  # by applying into a fresh HOME and asserting no symlinks back into the repo.
  if ! command -v chezmoi >/dev/null 2>&1; then
    print_warning "idempotency(file-types): skipped (chezmoi not installed)"
    return 0
  fi

  local temp_home
  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  HOME="$temp_home" chezmoi apply --source "$ROOT_DIR/chezmoi" --destination "$temp_home" >/dev/null

  local symlinks
  symlinks=$(find "$temp_home" -type l 2>/dev/null | wc -l | xargs)
  if [[ "$symlinks" -gt 0 ]]; then
    find "$temp_home" -type l 2>&1 | head -5
    fail "chezmoi-applied destination contains $symlinks symlink(s); expected only regular files"
  fi

  trap - RETURN
  rm -rf "$temp_home"

  print_success "idempotency(file-types): passed"
}

test_chezmoi_apply_idempotent
test_launchd_manager_idempotent
test_chezmoi_source_files_are_regular

print_success "idempotency: all checks passed"
