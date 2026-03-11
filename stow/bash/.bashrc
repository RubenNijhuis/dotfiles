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
export PATH="$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/go/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/opt/rustup/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/sbin:/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$PATH"

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

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell bash)"
fi

if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - --no-rehash bash)"
fi

# FZF keybindings and completion
_brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
if [[ -f "$_brew_prefix/opt/fzf/shell/key-bindings.bash" ]]; then
  source "$_brew_prefix/opt/fzf/shell/key-bindings.bash"
fi
if [[ -f "$_brew_prefix/opt/fzf/shell/completion.bash" ]]; then
  source "$_brew_prefix/opt/fzf/shell/completion.bash"
fi
unset _brew_prefix

# Local overrides (not committed)
[[ -f ~/.config/shell/local.sh ]] && source ~/.config/shell/local.sh

