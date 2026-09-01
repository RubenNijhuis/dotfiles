#!/usr/bin/env bash
# Refresh the Nix lockfile and verify the declared configuration.
#
# Legacy package managers are deliberately opt-in while the migration away from
# Homebrew and chezmoi is in progress.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/env.sh"
dotfiles_load_profile "$DOTFILES"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--exceptions] [--legacy]

Refresh Nix inputs, then evaluate and build the current configuration.

By default this only updates repositories and the Nix-managed environment. It
does not upgrade Homebrew, mise, or pnpm packages, and it never applies
chezmoi.

Options:
  --exceptions  Update only the documented Homebrew exceptions selected by the
                active machine profile.
  --legacy      Also run the pre-Nix Homebrew, mise, pnpm, and chezmoi steps.
                This implies --exceptions.
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

update_homebrew_exceptions() {
  print_section "Homebrew Exceptions"
  if ! command -v brew &>/dev/null; then
    print_status_row "Homebrew" warn "not found"
    return 1
  fi

  local brewfile_name brewfile

  print_status_row "Start" info "updating selected documented Nix exceptions"
  while IFS= read -r brewfile_name; do
    [[ -n "$brewfile_name" ]] || continue
    brewfile="$DOTFILES/brew/$brewfile_name"
    [[ -f "$brewfile" ]] || continue
    if ! brew bundle upgrade --file "$brewfile" &>/dev/null; then
      print_status_row "Homebrew" error "exception update failed ($(basename "$brewfile"))"
      return 1
    fi
  done < <(dotfiles_profile_brewfiles)

  print_status_row "Homebrew" ok "selected exceptions updated"
}

update_homebrew_legacy() {
  print_section "Legacy Homebrew"
  if ! command -v brew &>/dev/null; then
    print_status_row "Homebrew" warn "not found"
    return 1
  fi

  print_status_row "Start" warn "running broad legacy package update"
  if brew update &>/dev/null && brew upgrade &>/dev/null && brew cleanup &>/dev/null; then
    print_status_row "Homebrew" ok "legacy package update finished"
    return 0
  fi

  print_status_row "Homebrew" error "legacy update failed"
  return 1
}

update_nix_inputs() {
  print_section "Nix Inputs"
  if ! command -v nix &>/dev/null; then
    print_status_row "Nix" error "not found"
    return 1
  fi

  print_status_row "Start" info "refreshing flake.lock"
  if (cd "$DOTFILES" && nix flake update); then
    print_status_row "Nix" ok "flake inputs refreshed"
    return 0
  fi

  print_status_row "Nix" error "flake input update failed"
  return 1
}

verify_nix_configuration() {
  print_section "Nix Verification"
  if ! command -v nix &>/dev/null; then
    print_status_row "Nix" error "not found"
    return 1
  fi

  print_status_row "Check" info "evaluating all declared platforms"
  if ! (cd "$DOTFILES" && nix flake check --all-systems); then
    print_status_row "Check" error "flake evaluation failed"
    return 1
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    local darwin_host="${NIX_DARWIN_HOST:-Rubens-MacBook-Pro}"
    print_status_row "Build" info "building ${darwin_host} without switching"
    if (cd "$DOTFILES" && nix build ".#darwinConfigurations.${darwin_host}.system" --no-link); then
      print_status_row "Build" ok "macOS configuration builds"
      return 0
    fi
  else
    local system
    system="$(nix eval --impure --raw --expr builtins.currentSystem)"
    print_status_row "Build" info "building portable formatter for ${system}"
    if (cd "$DOTFILES" && nix build ".#packages.${system}.nixfmt-tree" --no-link); then
      print_status_row "Build" ok "portable Nix package builds"
      return 0
    fi
  fi

  print_status_row "Build" error "configuration build failed"
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
  local run_exceptions=false run_legacy=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        return 0
        ;;
      --no-color|--quiet)
        shift
        ;;
      --exceptions)
        run_exceptions=true
        shift
        ;;
      --legacy)
        run_legacy=true
        run_exceptions=true
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        return 1
        ;;
    esac
  done

  print_header "System Update"
  print_dim "Nix-first refresh: inputs, evaluation, and a build without switching."
  printf '\n'

  local failures=0

  # A repository pull may change the flake, so the Nix operations must follow
  # it and run sequentially against one coherent checkout.
  update_repos || failures=$((failures + 1))
  update_nix_inputs || failures=$((failures + 1))
  verify_nix_configuration || failures=$((failures + 1))

  if $run_exceptions && ! $run_legacy; then
    update_homebrew_exceptions || failures=$((failures + 1))
  fi

  if $run_legacy; then
    update_homebrew_legacy || failures=$((failures + 1))
    update_runtimes || failures=$((failures + 1))
    update_global_packages || failures=$((failures + 1))
    apply_chezmoi || failures=$((failures + 1))
  fi

  printf '\n'
  if [[ $failures -gt 0 ]]; then
    print_status_row "Overall" warn "$failures step(s) had issues"
    print_next_steps "Run: make doctor" "Review the failing Nix step before switching" "Use --legacy only for the transitional tools"
    exit 1
  fi

  print_status_row "Overall" ok "system update complete"
  print_next_steps "No action needed."
}

main "$@"
