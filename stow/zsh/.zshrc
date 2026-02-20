# Starship is the primary and only prompt backend.

# ----- Performance: Cache expensive operations -----

# Cache brew prefix (avoid subprocess on every shell startup)
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  export HOMEBREW_PREFIX="${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}"
fi

# ----- Completions (cached) -----
# Only regenerate completions once per day
autoload -Uz compinit
setopt EXTENDEDGLOB
local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${zcompdump}(#qNmh-20) ]]; then
  # Cached: use existing dump from last 20 hours
  compinit -C -d "$zcompdump"
else
  # Expired: regenerate dump
  compinit -d "$zcompdump"
fi
unsetopt EXTENDEDGLOB

# ----- History -----
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ----- Zsh options -----
setopt AUTO_CD
setopt CORRECT

# ----- Plugins (from Homebrew, cached paths) -----
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Defer syntax highlighting to background (it's slow and non-critical)
{
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
} &!

# ----- Tool initialization -----
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# LM Studio CLI
if [[ -d "${DOTFILES_LMSTUDIO_HOME:-$HOME/.lmstudio}/bin" ]]; then
  export PATH="$PATH:${DOTFILES_LMSTUDIO_HOME:-$HOME/.lmstudio}/bin"
fi

# ----- Shell config modules -----
source ~/.config/shell/path.sh
source ~/.config/shell/exports.sh
source ~/.config/shell/aliases.sh
source ~/.config/shell/functions.sh

# ----- Prompt -----
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%n@%m %1~ %# '
fi

# ----- Local overrides (not committed) -----
[[ -f ~/.config/shell/local.sh ]] && source ~/.config/shell/local.sh

# Ensure clean exit code
return 0 2>/dev/null || true
