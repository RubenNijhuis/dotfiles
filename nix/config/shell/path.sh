#!/usr/bin/env bash
# shellcheck disable=SC2123
# Nix-owned shared PATH construction.
# Portable PATH construction. First match wins: reproducible Nix tools take
# precedence, mise supplies only explicitly selected runtimes, and Homebrew is
# a fallback for macOS-specific or not-yet-migrated software.
_dotfiles_brew_prefix="${HOMEBREW_PREFIX:-${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}}"
_dotfiles_lmstudio_home="${DOTFILES_LMSTUDIO_HOME:-$HOME/.lmstudio}"
_dotfiles_nix_user="${USER:-$(id -un)}"
_dotfiles_old_path="${PATH:-}"

_dotfiles_path_add() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+${PATH}:}$1" ;;
  esac
}

PATH=""
for _dotfiles_path_entry in \
  "$HOME/.nix-profile/bin" \
  "/etc/profiles/per-user/${_dotfiles_nix_user}/bin" \
  "/run/current-system/sw/bin" \
  "/nix/var/nix/profiles/default/bin" \
  "$HOME/.local/share/mise/shims" \
  "$HOME/.bun/bin" \
  "$HOME/.local/share/pnpm/bin" \
  "$HOME/.cargo/bin" \
  "$HOME/go/bin" \
  "${_dotfiles_brew_prefix}/opt/rustup/bin" \
  "${_dotfiles_brew_prefix}/opt/dotnet@${DOTFILES_DOTNET_VERSION:-8}/bin" \
  "${_dotfiles_brew_prefix}/bin" \
  "${_dotfiles_brew_prefix}/sbin" \
  "/usr/bin" "/bin" "/usr/sbin" "/sbin" \
  "/usr/local/bin" "/usr/local/sbin" \
  "${_dotfiles_lmstudio_home}/bin" \
  "$HOME/.dotnet/tools" "$HOME/.spicetify" "$HOME/.local/bin"; do
  _dotfiles_path_add "$_dotfiles_path_entry"
done

while [ -n "$_dotfiles_old_path" ]; do
  case "$_dotfiles_old_path" in
    *:*)
      _dotfiles_path_entry="${_dotfiles_old_path%%:*}"
      _dotfiles_old_path="${_dotfiles_old_path#*:}"
      ;;
    *)
      _dotfiles_path_entry="$_dotfiles_old_path"
      _dotfiles_old_path=""
      ;;
  esac
  [ -n "$_dotfiles_path_entry" ] && _dotfiles_path_add "$_dotfiles_path_entry"
done

export PATH

unset _dotfiles_brew_prefix _dotfiles_lmstudio_home _dotfiles_nix_user \
  _dotfiles_old_path _dotfiles_path_entry
unset -f _dotfiles_path_add
