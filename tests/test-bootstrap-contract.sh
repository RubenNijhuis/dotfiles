#!/usr/bin/env bash
# Exercise bootstrap boundaries with mocks; never install, trust, or switch.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_INSTALL_SOURCE_ONLY=1 source "$ROOT_DIR/install.sh"

fail() { print_error "$1"; exit 1; }

test_tap_trust() (
  local calls=""
  brew_declared_taps() { printf '%s\n' reviewed/tap reviewed/tap; }
  brew() {
    [[ "$1" == trust && "$2" == --tap ]] || fail "Installer inspected installed taps for trust"
    calls="${calls}${3} "
  }
  brew_trust_declared_taps "$ROOT_DIR"
  [[ "$calls" == 'reviewed/tap ' ]] || fail "Tap trust was not limited and deduplicated"
  brew() { return 7; }
  if brew_trust_declared_taps "$ROOT_DIR"; then fail "Tap trust failure was ignored"; fi
)
test_tap_trust

test_profile_validation() (
  DOTFILES_PROFILE_BREWFILES=""
  [[ -z "$(brew_declared_taps "$ROOT_DIR")" ]] || fail "Empty profile gained taps"
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
print_success "bootstrap-contract: passed"
