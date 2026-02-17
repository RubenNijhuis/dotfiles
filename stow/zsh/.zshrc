# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----- Performance: Cache expensive operations -----

# Cache brew prefix (avoid subprocess on every shell startup)
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
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

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# ----- Shell config modules -----
source ~/.config/shell/path.sh
source ~/.config/shell/exports.sh
source ~/.config/shell/aliases.sh
source ~/.config/shell/functions.sh

# ----- Prompt -----
source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ----- Local overrides (not committed) -----
[[ -f ~/.config/shell/local.sh ]] && source ~/.config/shell/local.sh

# Ensure clean exit code
return 0 2>/dev/null || true

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/rubennijhuis/.lmstudio/bin"
# End of LM Studio CLI section

# OpenClaw Completion
source "/Users/rubennijhuis/.openclaw/completions/openclaw.zsh"
