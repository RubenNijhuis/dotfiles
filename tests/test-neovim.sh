#!/usr/bin/env bash
# Test public Lua and tool ownership without opening personal files or Mason.
set -euo pipefail
if ! command -v nvim >/dev/null 2>&1; then
  echo 'SKIP: Neovim unavailable'
  exit 0
fi
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
test_script=neovim.lua
if [[ -d "${1:-}" ]]; then
  mkdir -p "$test_root/config"
  ln -s "$1" "$test_root/config/dotfiles-test"
fi
if [[ "${2:-}" == --smoke ]]; then
  [[ -d "${1:-}" ]] || { echo 'Built configuration required for --smoke' >&2; exit 1; }
  test_script=neovim-smoke.lua
fi
XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data" \
  XDG_STATE_HOME="$test_root/state" XDG_CACHE_HOME="$test_root/cache" \
  NVIM_APPNAME=dotfiles-test DOTFILES_TEST_ROOT="$repo_root" \
  nvim --headless -u NONE -i NONE -l "$repo_root/tests/$test_script" "${1:-}" "${2:-}"
