#!/usr/bin/env bash
# Idempotency checks for high-risk operational scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/output.sh" "$@"

fail() {
  print_error "$1"
  exit 1
}

test_stow_all_idempotent() {
  if ! command -v stow >/dev/null 2>&1; then
    print_warning "idempotency(stow): skipped (stow not installed)"
    return 0
  fi

  local temp_home
  local listing1
  local listing2

  temp_home="$(mktemp -d)"
  trap 'rm -rf "$temp_home"' RETURN

  HOME="$temp_home" bash "$ROOT_DIR/scripts/bootstrap/stow-all.sh" --no-color >/dev/null

  listing1="$(mktemp)"
  listing2="$(mktemp)"

  find "$temp_home" -type l -print | sort > "$listing1"

  HOME="$temp_home" bash "$ROOT_DIR/scripts/bootstrap/stow-all.sh" --no-color >/dev/null
  find "$temp_home" -type l -print | sort > "$listing2"

  if ! diff -u "$listing1" "$listing2" >/dev/null; then
    diff -u "$listing1" "$listing2" || true
    fail "stow-all changed symlink set on second run"
  fi

  local broken
  broken=$(find -L "$temp_home" -type l | wc -l | xargs)
  if [[ "$broken" -gt 0 ]]; then
    fail "stow-all created $broken broken symlink(s)"
  fi

  rm -f "$listing1" "$listing2"
  trap - RETURN
  rm -rf "$temp_home"

  print_success "idempotency(stow): passed"
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

  manager="$ROOT_DIR/scripts/automation/launchd-manager.sh"

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

test_stow_all_idempotent
test_launchd_manager_idempotent

print_success "idempotency: all checks passed"
