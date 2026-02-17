# shellcheck shell=bash disable=SC2206
# PATH construction - order matters (first match wins)
typeset -U PATH  # Remove duplicates

path=(
    "$HOME/.bun/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "$HOME/.lmstudio/bin"
    "/opt/homebrew/opt/dotnet@8/bin"
    "$HOME/.dotnet/tools"
    "$HOME/.local/bin"
    $path
)
