#!/usr/bin/env bash
# Refresh the Nix lockfile and verify the declared configuration.
#
# Homebrew remains opt-in for documented macOS-only exceptions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/env.sh"
dotfiles_load_profile "$DOTFILES"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--exceptions]

Refresh Nix inputs, then evaluate and build the current configuration.
Activation remains explicit; this command does not switch the running system.

By default this only updates repositories and the Nix-managed environment.

Options:
  --exceptions  Update only the documented Homebrew exceptions selected by the
                active machine profile.
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
  if ! dotfiles_profile_brewfiles | grep -q .; then
    print_status_row "Homebrew" ok "no exceptions selected; Nix owns this profile"
    return 0
  fi

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
  if ! (cd "$DOTFILES" && nix flake check --all-systems --no-build); then
    print_status_row "Check" error "flake evaluation failed"
    return 1
  fi

  local system
  system="$(nix eval --impure --raw --expr builtins.currentSystem)"
  print_status_row "Editor" info "testing fresh-profile Neovim on ${system}"
  if ! (cd "$DOTFILES" && nix build ".#checks.${system}.neovim" --no-link); then
    print_status_row "Editor" error "Neovim runtime check failed; do not activate this update"
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
    print_status_row "Build" info "building portable formatter for ${system}"
    if (cd "$DOTFILES" && nix build ".#packages.${system}.nixfmt-tree" --no-link); then
      print_status_row "Build" ok "portable Nix package builds"
      return 0
    fi
  fi

  print_status_row "Build" error "configuration build failed"
  return 1
}

main() {
  local run_exceptions=false
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

  if $run_exceptions; then
    update_homebrew_exceptions || failures=$((failures + 1))
  fi

  printf '\n'
  if [[ $failures -gt 0 ]]; then
    print_status_row "Overall" warn "$failures step(s) had issues"
    print_next_steps "Run: make doctor" "Review the failing Nix step before switching"
    exit 1
  fi

  print_status_row "Overall" ok "configuration refreshed and verified; not activated"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    print_next_steps "Run make nix-switch to activate the verified configuration."
  else
    print_next_steps "Run make nix-home-switch NIX_HOME_HOST=<host> to activate your home configuration."
  fi
}

main "$@"
