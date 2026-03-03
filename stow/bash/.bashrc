# Bash configuration — sources shared shell modules
# Primary shell is zsh; this provides a sane fallback for bash subshells.

# Exit early for non-interactive shells
[[ $- != *i* ]] && return

# Homebrew
if [[ -x "${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew" ]]; then
  eval "$("${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew" shellenv)"
fi

# History
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Shell options
shopt -s autocd 2>/dev/null
shopt -s cdspell
shopt -s dirspell 2>/dev/null

# PATH (manual, since path.sh uses zsh-specific syntax)
export PATH="$HOME/.bun/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/sbin:/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$PATH"

# Shared shell modules (bash-compatible)
source ~/.config/shell/exports.sh
source ~/.config/shell/aliases.sh
source ~/.config/shell/functions.sh

# Tool initialization
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
else
  PS1='\u@\h \W \$ '
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init bash --disable-up-arrow)"
fi

# Local overrides (not committed)
[[ -f ~/.config/shell/local.sh ]] && source ~/.config/shell/local.sh
