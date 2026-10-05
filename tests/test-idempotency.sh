#!/usr/bin/env bash
# Idempotency checks for high-risk operational scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"

fail() {
  print_error "$1"
  exit 1
}

test_empty_automation_profile() (
  set -euo pipefail
  LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$ROOT_DIR/ops/automation/launchd-manager.sh"
  DOTFILES_PROFILE_AUTOMATIONS=""
  [[ -z "$(dotfiles_profile_automations)" ]] || fail "Empty profile expanded into jobs"
  [[ -z "$(profile_agent_infos)" ]] || fail "Empty manager profile selected jobs"
  DOTFILES_PROFILE_AUTOMATIONS="update-audit"
  [[ "$(dotfiles_profile_automations)" == update-audit ]] || fail "Explicit selection lost"
  [[ "$(profile_agent_infos)" == update-audit:* ]] || fail "Manager selection mismatch"
  [[ "$(automation_resolve_alias backup)" == dotfiles-backup ]] || fail "Backup alias mismatch"
  [[ "$(automation_resolve_alias updates)" == update-audit ]] || fail "Update alias mismatch"
)
test_empty_automation_profile

test_files_structure() (
  set -euo pipefail
  local fixture folder
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  export DOTFILES_FILES_ROOT="$fixture/Files"
  export DOTFILES_PRIVATE_ROOT="$fixture/Private"
  for _ in 1 2; do
    bash "$ROOT_DIR/setup/create-files-root.sh" >/dev/null
  done
  for folder in '00 Inbox' '10 Projects' '20 Areas' '30 Resources' '40 Archive' '90 Shared'; do
    [[ -d "$DOTFILES_FILES_ROOT/$folder" ]] || fail "Missing Files category: $folder"
  done
  [[ -d "$DOTFILES_PRIVATE_ROOT/Credentials/Exports" &&
     -d "$DOTFILES_PRIVATE_ROOT/Migrations" &&
     -d "$DOTFILES_PRIVATE_ROOT/Recovery Codes" ]] || fail "Missing technical storage"
  [[ ! -e "$DOTFILES_PRIVATE_ROOT/Identity" ]] || fail "Created device-only identity library"
  [[ "$(find "$DOTFILES_PRIVATE_ROOT" -type d ! -perm 700 -print)" == "" ]] || fail "Technical storage permissions"
)
test_files_structure

test_pinned_nix_switch() (
  set -euo pipefail
  local preview
  preview="$(make -n -C "$ROOT_DIR" nix-switch NIX=nix NIX_DARWIN_HOST=fixture-host)"
  # Match Make's literal shell variable, not a variable in this test.
  # shellcheck disable=SC2016
  [[ "$preview" == *'.#darwinConfigurations.fixture-host.config.system.build.darwin-rebuild'* &&
     "$preview" == *'--no-link --print-out-paths --no-write-lock-file'* &&
     "$preview" == *'&&'* &&
     "$preview" == *'sudo -H "$rebuild/bin/darwin-rebuild"'* &&
     "$preview" == *'switch --flake .#fixture-host --no-write-lock-file'* ]] || fail "Unpinned activation tool"
  [[ "$preview" != *'github:nix-darwin'* ]] || fail "Activation fetches unlocked upstream"
)
test_pinned_nix_switch

test_formatter_failure() (
  set -euo pipefail
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  printf '#!/bin/sh\nexit 7\n' > "$fixture/biome"
  chmod +x "$fixture/biome"
  if PATH="$fixture:$PATH" bash "$ROOT_DIR/ops/format-all.sh" >/dev/null 2>&1; then
    fail "Formatter errors were reported as success"
  fi
)
test_formatter_failure

test_lock_metadata_failure() (
  set -euo pipefail
  local fixture
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  source "$ROOT_DIR/lib/common.sh"
  mkdir "$fixture/dotfiles-metadata-failure.lock"
  touch "$fixture/dotfiles-metadata-failure.lock/sentinel"
  stat() { return 1; }
  if TMPDIR="$fixture" acquire_lock metadata-failure >/dev/null 2>&1; then
    trap 'rm -rf "$fixture"' EXIT
    fail "Missing metadata allowed an existing lock to be removed"
  fi
  [[ -f "$fixture/dotfiles-metadata-failure.lock/sentinel" ]] || fail "Existing lock was altered"
)
test_lock_metadata_failure


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

test_launchd_manager_idempotent

print_success "idempotency: all checks passed"
