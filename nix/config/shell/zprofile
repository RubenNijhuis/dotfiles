if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
elif [[ -x "${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew" ]]; then
  eval "$("${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew" shellenv)"
fi
