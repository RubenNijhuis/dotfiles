#!/usr/bin/env bash
# Shared environment defaults for dotfiles scripts.

dotfiles_load_env() {
  local dotfiles_root="${1:-${DOTFILES:-}}"

  if [[ -z "$dotfiles_root" ]]; then
    dotfiles_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  fi

  # Optional machine-local overrides.
  if [[ -f "$dotfiles_root/local/machine.env" ]]; then
    # shellcheck disable=SC1090
    source "$dotfiles_root/local/machine.env"
  fi

  if [[ -z "${DOTFILES_HOMEBREW_PREFIX:-}" ]]; then
    if command -v brew >/dev/null 2>&1; then
      DOTFILES_HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
    fi
    DOTFILES_HOMEBREW_PREFIX="${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}"
  fi

  export DOTFILES_DEVELOPER_ROOT="${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"
  export DOTFILES_OPENCLAW_HOME="${DOTFILES_OPENCLAW_HOME:-$HOME/.openclaw}"
  export DOTFILES_LMSTUDIO_HOME="${DOTFILES_LMSTUDIO_HOME:-$HOME/.lmstudio}"
  export DOTFILES_EDITOR="${DOTFILES_EDITOR:-code --wait}"
  export DOTFILES_HOMEBREW_PREFIX
  export DOTFILES_OBSIDIAN_REPO_PATH="${DOTFILES_OBSIDIAN_REPO_PATH:-$DOTFILES_DEVELOPER_ROOT/personal/projects/obsidian-store}"
}
