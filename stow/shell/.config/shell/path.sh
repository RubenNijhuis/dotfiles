# PATH construction - order matters (first match wins)
typeset -U PATH  # Remove duplicates

path=(
    "$HOME/.bun/bin"
    "$HOME/.lmstudio/bin"
    "/opt/homebrew/opt/dotnet@8/bin"
    "$HOME/.dotnet/tools"
    "$HOME/.local/bin"
    $path
)
