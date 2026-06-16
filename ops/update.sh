#!/usr/bin/env bash
# Update repos, brew packages, runtimes, global packages, and re-stow configs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"
# shellcheck source=../lib/parallel.sh
source "$SCRIPT_DIR/../lib/parallel.sh"

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

apply_chezmoi() {
  print_section "Config Sync"
  print_status_row "Start" info "reapplying chezmoi source state to \$HOME"

  if ! command -v chezmoi >/dev/null 2>&1; then
    print_status_row "chezmoi" error "not installed (brew install chezmoi)"
    return 1
  fi
  if chezmoi apply 2>/dev/null; then
    local pending
    pending=$(chezmoi status 2>/dev/null | wc -l | xargs)
    print_status_row "chezmoi" ok "applied (${pending} pending after)"
    return 0
  fi
  print_status_row "chezmoi" error "apply failed — run: chezmoi diff"
  return 1
}

main() {
  parse_standard_args usage "$@"
  print_header "System Update"
  print_dim "Compact progress view for repositories, packages, runtimes, and config sync."
  printf '\n'

  local failures=0
  UPDATE_TMP="$(parallel_tmpdir update)"
  trap 'rm -rf "${UPDATE_TMP:-}"' EXIT

  # Fan out independent steps. Restow must run after because brew/runtimes
  # can change files the symlink farm references.
  local steps=(repos brew runtimes global)
  parallel_spawn "$UPDATE_TMP" repos    update_repos
  parallel_spawn "$UPDATE_TMP" brew     update_homebrew
  parallel_spawn "$UPDATE_TMP" runtimes update_runtimes
  parallel_spawn "$UPDATE_TMP" global   update_global_packages
  parallel_wait

  parallel_replay "$UPDATE_TMP" "${steps[@]}"
  failures=$((failures + $(parallel_failures "$UPDATE_TMP" "${steps[@]}")))

  apply_chezmoi || failures=$((failures + 1))

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
