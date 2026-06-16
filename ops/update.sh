#!/usr/bin/env bash
# Update repos, brew packages, runtimes, global packages, and re-stow configs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Update repos, Homebrew packages, runtime tools, global packages, and restow configs.
EOF
}

update_repos() {
  print_section "Repositories"
  print_status_row "Start" info "checking local repositories for upstream changes"

  if bash "$DOTFILES/ops/update-repos.sh" --compact ${NO_COLOR:+--no-color}; then
    print_status_row "Result" ok "repository scan complete"
    return 0
  fi
  print_status_row "Result" warn "repository updates had issues"
  return 1
}

update_homebrew() {
  print_section "Homebrew"
  if ! command -v brew &>/dev/null; then
    print_status_row "Homebrew" warn "not found"
    return 1
  fi

  local outdated_count
  outdated_count=$(brew outdated 2>/dev/null | wc -l | xargs || echo "0")
  print_status_row "Start" info "refreshing taps, upgrades, and cleanup"
  brew autoremove &>/dev/null || true

  if brew update &>/dev/null && brew upgrade &>/dev/null && brew cleanup &>/dev/null; then
    print_status_row "Homebrew" ok "${outdated_count} package(s) needed attention"
    return 0
  fi

  print_status_row "Homebrew" error "update failed"
  return 1
}

update_runtimes() {
  print_section "Runtimes"
  if ! command -v mise &>/dev/null; then
    print_status_row "mise" info "not installed"
    return 0
  fi

  print_status_row "Start" info "upgrading managed runtimes"
  if mise upgrade &>/dev/null; then
    print_status_row "mise" ok "upgrade finished"
  else
    print_status_row "mise" warn "upgrade failed"
  fi
}

update_global_packages() {
  print_section "Global Packages"
  if ! command -v pnpm &>/dev/null; then
    print_status_row "pnpm" info "not installed"
    return 0
  fi

  print_status_row "Start" info "updating global pnpm packages"
  if pnpm update -g &>/dev/null; then
    print_status_row "pnpm" ok "global packages updated"
  else
    print_status_row "pnpm" warn "update failed"
  fi
}

restow_configs() {
  print_section "Config Sync"
  print_status_row "Start" info "reapplying stow packages"

  local output
  if output=$(bash "$DOTFILES/setup/stow-all.sh" --quiet ${NO_COLOR:+--no-color} 2>&1); then
    print_status_row "Stow" ok "$output"
    return 0
  fi
  print_status_row "Stow" error "failed"
  return 1
}

# Run a subsystem function, capturing stdout/stderr to a buffer file and
# its exit code to a sibling .rc file. Designed for backgrounded parallel use.
run_buffered() {
  local fn="$1" buf="$2"
  if "$fn" >"$buf" 2>&1; then
    printf '0\n' > "${buf}.rc"
  else
    printf '%s\n' "$?" > "${buf}.rc"
  fi
}

main() {
  parse_standard_args usage "$@"
  print_header "System Update"
  print_dim "Compact progress view for repositories, packages, runtimes, and config sync."
  printf '\n'

  local failures=0
  UPDATE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-update.XXXXXX")"
  trap 'rm -rf "${UPDATE_TMP:-}"' EXIT
  local tmp="$UPDATE_TMP"

  # Fan out independent steps. Restow must run after because brew/runtimes
  # can change files the symlink farm references.
  run_buffered update_repos           "$tmp/repos" &
  run_buffered update_homebrew        "$tmp/brew" &
  run_buffered update_runtimes        "$tmp/runtimes" &
  run_buffered update_global_packages "$tmp/global" &
  wait

  # Replay buffered output in deterministic order.
  for step in repos brew runtimes global; do
    cat "$tmp/$step"
    local rc
    rc="$(cat "$tmp/${step}.rc" 2>/dev/null || echo 1)"
    [[ "$rc" != "0" ]] && failures=$((failures + 1))
  done

  restow_configs || failures=$((failures + 1))

  printf '\n'
  if [[ $failures -gt 0 ]]; then
    print_status_row "Overall" warn "$failures step(s) had issues"
    print_next_steps "Run: make doctor" "Run: make ops-status" "Run: make brew-audit if Brewfiles drifted"
    exit 1
  fi

  print_status_row "Overall" ok "system update complete"
  print_next_steps "No action needed."
}

main "$@"
