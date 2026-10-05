#!/usr/bin/env bash
# SCRIPT_VISIBILITY: launchd-internal
# Report available Nix, Homebrew, and macOS updates without changing the system.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/output.sh" "$@"
export PATH="/etc/profiles/per-user/$(id -un)/bin:$PATH"

if ! require_network; then
  print_info "Offline — skipping update audit"
  exit 0
fi

lock_dir="${TMPDIR:-/tmp}/dotfiles-update-audit.lock"
cleanup() {
  rm -f "$lock_dir/pid" "$lock_dir/flake.lock" "$lock_dir/nix.log" "$lock_dir/report"
  rmdir "$lock_dir" 2>/dev/null || true
}
# Recover the exact lock after a killed audit. Never remove a live audit's lock.
if [[ -f "$lock_dir/pid" ]]; then
  read -r lock_pid < "$lock_dir/pid"
  if [[ "$lock_pid" =~ ^[0-9]+$ ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
    cleanup
  fi
fi
if ! mkdir "$lock_dir" 2>/dev/null; then
  print_info "Another update audit is already running"
  exit 0
fi
printf '%s\n' "$$" > "$lock_dir/pid"
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

available=()
failed=()

check_nix() {
  local nix_bin temporary_lock changes desired_system current_system
  nix_bin="$(command -v nix || true)"
  [[ -n "$nix_bin" ]] || { failed+=("Nix unavailable"); return; }
  command -v jq >/dev/null || { failed+=("Nix check requires jq"); return; }

  temporary_lock="$lock_dir/flake.lock"

  if "$nix_bin" flake update --flake "$DOTFILES" --output-lock-file "$temporary_lock" >"$lock_dir/nix.log" 2>&1; then
    if [[ ! -s "$temporary_lock" ]]; then
      failed+=("Nix check produced no lockfile")
    elif ! cmp -s "$DOTFILES/flake.lock" "$temporary_lock"; then
      changes="$(jq -nr --slurpfile old "$DOTFILES/flake.lock" --slurpfile new "$temporary_lock" '
        $new[0].nodes | to_entries[] |
        select(.value.locked != $old[0].nodes[.key].locked) | .key')"
      available+=("Nix inputs: ${changes//$'\n'/, }")
    fi
  else
    failed+=("Nix check")
    cat "$lock_dir/nix.log" >&2
  fi

  rm -f "$temporary_lock"

  # A refreshed lockfile can be current while the running Mac is still old.
  if [[ "$(uname -s)" == Darwin && -d /run/current-system ]]; then
    if desired_system="$("$nix_bin" eval --raw --no-write-lock-file \
      "$DOTFILES#darwinConfigurations.${NIX_DARWIN_HOST:-Rubens-MacBook-Pro}.system.outPath" 2>>"$lock_dir/nix.log")"; then
      current_system="$(cd /run/current-system && pwd -P)"
      if [[ "$desired_system" != "$current_system" ]]; then
        available+=("Nix configuration updated; activation pending (make nix-switch)")
      fi
    else
      failed+=("Nix activation status")
      cat "$lock_dir/nix.log" >&2
    fi
  fi
}

check_homebrew() {
  local brew_bin outdated
  brew_bin="$(command -v brew || true)"
  [[ -n "$brew_bin" ]] || return

  if ! outdated="$("$brew_bin" outdated --verbose 2>/dev/null)"; then
    failed+=("Homebrew check")
  elif [[ -n "$outdated" ]]; then
    available+=("Homebrew packages:" "$outdated")
  fi
}

check_macos() {
  local output
  if ! output="$(/usr/sbin/softwareupdate --list 2>&1)"; then
    failed+=("macOS check")
  elif grep -q '^\* Label:' <<< "$output"; then
    available+=("Apple software:" "$(sed -n 's/^\* Label: /  /p' <<< "$output")")
  elif ! grep -q "No new software available" <<< "$output"; then
    failed+=("Unrecognised macOS update response")
  fi
}

print_header "Update Audit"
check_nix
check_homebrew
check_macos

{
  if [[ ${#available[@]} -eq 0 && ${#failed[@]} -eq 0 ]]; then
    printf 'No updates found by the Nix, Homebrew, or macOS checks.\n'
  fi
  if [[ ${#available[@]} -gt 0 ]]; then printf '%s\n' "${available[@]}"; fi
  if [[ ${#failed[@]} -gt 0 ]]; then printf 'Checks failed: %s\n' "${failed[*]}"; fi
  printf '\nNix: nix flake update && make nix-build && make nix-switch\n'
  printf 'Homebrew: review brew outdated --verbose, then brew upgrade <package names>\n'
  printf 'Apple updates: System Settings > General > Software Update\n'
} > "$lock_dir/report"
cat "$lock_dir/report"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
mkdir -p "$state_dir"
if ! cmp -s "$lock_dir/report" "$state_dir/update-audit.txt"; then
  cp "$lock_dir/report" "$state_dir/update-audit.txt"
  if [[ ${#failed[@]} -gt 0 ]]; then
    notify "Update Audit" "Some checks failed. See ~/.local/state/dotfiles/update-audit.txt"
  elif [[ ${#available[@]} -gt 0 ]]; then
    notify "Updates Available" "See ~/.local/state/dotfiles/update-audit.txt for packages and next steps"
  fi
fi
if [[ ${#failed[@]} -gt 0 ]]; then exit 1; fi
