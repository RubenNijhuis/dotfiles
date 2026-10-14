#!/usr/bin/env bash
# Exercise bootstrap boundaries with mocks; never install, trust, or switch.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_INSTALL_SOURCE_ONLY=1 source "$ROOT_DIR/install.sh"

fail() { print_error "$1"; exit 1; }

test_tap_trust() (
  local calls=""
  # shellcheck disable=SC2329 # Invoked by the sourced tap-trust helper.
  brew_declared_taps() { printf '%s\n' reviewed/tap reviewed/tap; }
  # shellcheck disable=SC2329 # Invoked by the sourced tap-trust helper.
  brew() {
    [[ "$1" == trust && "$2" == --tap ]] || fail "Installer inspected installed taps for trust"
    calls="${calls}${3} "
  }
  brew_trust_declared_taps "$ROOT_DIR"
  [[ "$calls" == 'reviewed/tap ' ]] || fail "Tap trust was not limited and deduplicated"
  # shellcheck disable=SC2329 # Invoked by the sourced tap-trust helper.
  brew() { return 7; }
  if brew_trust_declared_taps "$ROOT_DIR"; then fail "Tap trust failure was ignored"; fi
)
test_tap_trust

test_profile_validation() (
  # shellcheck disable=SC2034 # Read by the sourced profile-selection helper.
  DOTFILES_PROFILE_BREWFILES=""
  [[ -z "$(brew_declared_taps "$ROOT_DIR")" ]] || fail "Empty profile gained taps"
  # shellcheck disable=SC2034 # Read by the sourced profile-selection helper.
  DOTFILES_PROFILE_BREWFILES="Brewfile.not-present"
  if brew_trust_declared_taps "$ROOT_DIR" 2>/dev/null; then fail "Missing Brewfile was ignored"; fi
)
test_profile_validation

test_empty_tap_audit() (
  # A fresh Homebrew install has no third-party taps. No real brew calls.
  # shellcheck disable=SC2329 # Exported for the child audit processes.
  brew() {
    case "$*" in
      --prefix) printf '/fixture/homebrew\n' ;;
      tap) ;;
      'leaves --installed-on-request'|'list --formula') printf 'pinentry-mac\n' ;;
      'list --cask') printf '%s\n' handbrake-app krita prismlauncher rawtherapee zulu@17 ;;
      *) fail "Unexpected brew operation: $*" ;;
    esac
  }
  export -f brew fail
  DOTFILES_PROFILE=personal-laptop bash "$ROOT_DIR/ops/brew-audit.sh" --check --no-color >/dev/null
  if DOTFILES_PROFILE=minimal bash "$ROOT_DIR/ops/brew-audit.sh" --check --no-color >/dev/null; then
    fail "Nix-only profile concealed installed Homebrew leftovers"
  fi
)
test_empty_tap_audit

test_host_guard() (
  OS=Darwin ARCH=x86_64
  if (step_detect_system) >/dev/null 2>&1; then fail "Intel Mac accepted Apple Silicon target"; fi
  ARCH=arm64
  id() { printf 'other-user\n'; }
  if (step_detect_system) >/dev/null 2>&1; then fail "Different user accepted personal home target"; fi
)
test_host_guard

test_pinned_switch_failure() (
  # The system switch must never follow a failed evaluation/build.
  make() { return 7; }
  if (step_verify_nix_configuration && step_apply_nix_configuration) >/dev/null 2>&1; then
    fail "Failed build allowed activation"
  fi
)
test_pinned_switch_failure

test_final_setup_failure() (
  local fixture
  fixture=$(mktemp -d)
  trap 'rm -rf "$fixture"' EXIT
  DEVELOPER_ROOT="$fixture/Developer"
  SETUP_SSH=no SETUP_GPG=no
  git() { return 7; }
  if step_finish_nix_install >/dev/null; then fail "Failed hook setup passed the final local setup"; fi
  SETUP_SSH=yes
  bash() { return 8; }
  if step_finish_nix_install >/dev/null; then fail "Failed key setup passed the final local setup"; fi
)
test_final_setup_failure

test_selected_setup() (
  local fixture calls
  fixture=$(mktemp -d)
  trap 'rm -rf "$fixture"' EXIT
  calls="$fixture/calls"
  # The declared editor's profile and activated settings are entirely fake.
  mkdir -p "$fixture/profile/bin" "$fixture/Library/Application Support/Code/User"
  touch "$fixture/profile/bin/code" "$fixture/settings.json"
  chmod +x "$fixture/profile/bin/code"
  ln -s "$fixture/settings.json" "$fixture/Library/Application Support/Code/User/settings.json"
  HOME="$fixture"
  local editor_selected=true eval_failed=false setup_failed=false
  nix() {
    [[ "$*" == *'--offline --no-write-lock-file'* ]] || fail "Setup evaluation could contact the network/write the lock"
    $eval_failed && return 9
    case "$*" in
      *home.file*) printf '%s\n' "$editor_selected" ;;
      *home.path*) printf '%s\n' "$fixture/profile" ;;
      *) fail "Unexpected setup evaluation" ;;
    esac
  }
  bash() {
    printf '%s\n' "$*" >> "$calls"
    if [[ "$1" == */vscode-setup.sh ]]; then
      [[ "$(command -v code)" == "$fixture/profile/bin/code" ]] || fail "Setup adopted the ambient VS Code CLI"
    fi
    $setup_failed && return 8
    return 0
  }

  DOTFILES_PROFILE_AUTOMATIONS='update-audit update-audit'
  DRY_RUN=true
  step_reconcile_selected_setup >/dev/null
  [[ ! -e "$calls" ]] || fail "Preview invoked a setup script"
  DRY_RUN=false
  step_reconcile_selected_setup >/dev/null
  [[ "$(wc -l < "$calls" | tr -d ' ')" == 2 ]] || fail "Selected setup did not run exactly once per component"
  [[ "$(tail -1 "$calls")" == *'--no-color --strict setup-all' ]] || fail "Selected prerequisites could be silently skipped"

  rm "$calls"
  editor_selected=false
  DOTFILES_PROFILE_AUTOMATIONS=''
  step_reconcile_selected_setup >/dev/null
  [[ ! -e "$calls" ]] || fail "Disabled components were installed"

  DOTFILES_PROFILE_AUTOMATIONS='update-audit unknown-job'
  if step_reconcile_selected_setup >/dev/null 2>&1; then fail "Unknown automation selection succeeded"; fi
  [[ ! -e "$calls" ]] || fail "Invalid profile partially installed jobs"
  DOTFILES_PROFILE_AUTOMATIONS=''
  editor_selected=true
  rm "$fixture/Library/Application Support/Code/User/settings.json"
  if step_reconcile_selected_setup >/dev/null 2>&1; then fail "Unactivated editor configuration succeeded"; fi
  ln -s "$fixture/settings.json" "$fixture/Library/Application Support/Code/User/settings.json"
  rm "$fixture/profile/bin/code"
  if step_reconcile_selected_setup >/dev/null 2>&1; then fail "Missing selected editor CLI succeeded"; fi
  touch "$fixture/profile/bin/code"
  chmod +x "$fixture/profile/bin/code"

  # A failed final setup cannot advance the saved step; --yes resumes step 8.
  CHECKPOINT_FILE="$fixture/checkpoint"
  CURRENT_STEP=7
  save_checkpoint
  setup_failed=true
  if run_step 8 step_reconcile_selected_setup >/dev/null; then fail "Setup failure finished its checkpoint"; fi
  [[ "$(load_checkpoint)" == 7 ]] || fail "Failed setup advanced checkpoint"
  CURRENT_STEP=0 NON_INTERACTIVE=true
  handle_resume >/dev/null
  [[ "$CURRENT_STEP" == 7 ]] || fail "--yes failed to resume the final setup"
  setup_failed=false
  run_step 8 step_reconcile_selected_setup >/dev/null
  [[ "$(load_checkpoint)" == 8 ]] || fail "Successful setup did not finish its checkpoint"
  eval_failed=true
  if step_reconcile_selected_setup >/dev/null 2>&1; then fail "Nix evaluation failure was treated as an absent editor"; fi
)
test_selected_setup

test_automation_setup() (
  local fixture result=0 checksum
  fixture=$(mktemp -d)
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/lib" "$fixture/profiles" "$fixture/ops/automation" "$fixture/launchd" "$fixture/home"
  cp "$ROOT_DIR/lib/"{common,output,env,automation-registry}.sh "$fixture/lib/"
  cp "$ROOT_DIR/ops/automation/"{setup-automation,launchd-manager}.sh "$ROOT_DIR/ops/automation/agents.manifest" "$fixture/ops/automation/"
  cp "$ROOT_DIR/launchd/com.user.update-audit.plist" "$fixture/launchd/"
  # shellcheck disable=SC2016 # The fixture profile expands this in its child.
  printf '%s\n' 'DOTFILES_PROFILE="personal-laptop"' \
    'DOTFILES_PROFILE_AUTOMATIONS="${AUTOMATION_TEST_SELECTED:-}"' > "$fixture/profiles/personal-laptop.env"
  export AUTOMATION_TEST_CALLS="$fixture/calls"
  # shellcheck disable=SC2329 # Exported into the real setup/manager children.
  launchctl() { printf '%s\n' "$*" >> "$AUTOMATION_TEST_CALLS"; }
  export -f launchctl
  run_automation() {
    HOME="$fixture/home" DOTFILES_PROFILE=personal-laptop DOTFILES_HOMEBREW_PREFIX=/fixture/brew \
      AUTOMATION_TEST_SELECTED="$1" bash "$fixture/ops/automation/setup-automation.sh" \
      --no-color "${@:2}" setup-all > "$fixture/output" 2>&1
  }
  run_automation 'update-audit update-audit' --strict
  [[ "$(wc -l < "$fixture/calls" | tr -d ' ')" == 1 ]] || fail "Repeated profile selection loaded duplicate jobs"
  checksum=$(cksum "$fixture/home/Library/LaunchAgents/com.user.update-audit.plist")
  run_automation update-audit --strict
  [[ "$(cksum "$fixture/home/Library/LaunchAgents/com.user.update-audit.plist")" == "$checksum" ]] || fail "Repeated setup changed the rendered job"
  [[ "$(grep -c '^bootstrap ' "$fixture/calls")" == 2 ]] || fail "Repeated setup changed job ownership"
  rm "$fixture/calls"
  run_automation '' --strict
  [[ ! -e "$fixture/calls" ]] || fail "Empty profile loaded a job"
  run_automation 'update-audit unknown-job' --strict || result=$?
  [[ "$result" == 1 && ! -e "$fixture/calls" ]] || fail "Invalid selection partially loaded jobs"
  result=0
  run_automation lmstudio-server --strict || result=$?
  [[ "$result" == 1 && ! -e "$fixture/calls" ]] || fail "Missing selected prerequisite passed strict setup"
  run_automation lmstudio-server
)
test_automation_setup
print_success "bootstrap-contract: passed"
