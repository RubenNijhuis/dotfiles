# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----- Completions -----
autoload -Uz compinit && compinit

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

# ----- Plugins (from Homebrew) -----
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ----- Local overrides (not committed) -----
[[ -f ~/.config/shell/local.sh ]] && source ~/.config/shell/local.sh
