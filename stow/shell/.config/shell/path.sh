# shellcheck shell=bash disable=SC2206
# PATH construction - order matters (first match wins)
typeset -U PATH  # Remove duplicates
_brew_prefix="${HOMEBREW_PREFIX:-${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}}"
_lmstudio_home="${DOTFILES_LMSTUDIO_HOME:-$HOME/.lmstudio}"

path=(
    "$HOME/.bun/bin"
    "$_brew_prefix/bin"
    "$_brew_prefix/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "$_lmstudio_home/bin"
    "$_brew_prefix/opt/dotnet@8/bin"
    "$HOME/.dotnet/tools"
    "$HOME/.local/bin"
    $path
)
