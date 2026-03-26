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
export PATH="$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.dotnet/tools:${HOMEBREW_PREFIX:-/opt/homebrew}/opt/dotnet@${DOTFILES_DOTNET_VERSION:-8}/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/opt/rustup/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/bin:${HOMEBREW_PREFIX:-/opt/homebrew}/sbin:/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$PATH"

# Shared shell modules (bash-compatible)
source ~/.config/shell/exports.sh
source ~/.config/shell/aliases.sh
source ~/.config/shell/functions.sh

# ----- Eval caching (mirrors zsh _zsh_eval_cache pattern) -----
# Caches eval output in ~/.cache/bash/ and invalidates when the binary changes.
_bash_eval_cache() {
  local cmd="$1"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/bash"
  local cache_file="$cache_dir/${cmd}.bash"
  local bin_path
  bin_path="$(command -v "$cmd" 2>/dev/null || true)"

  if [[ -z "$bin_path" ]]; then
    return 1
  fi

  if [[ ! -f "$cache_file" ]] || [[ "$bin_path" -nt "$cache_file" ]]; then
    mkdir -p "$cache_dir"
    "$@" > "$cache_file" 2>/dev/null
    if [[ ! -s "$cache_file" ]]; then
      rm -f "$cache_file"
      return 1
    fi
  fi
  source "$cache_file"
}

# Tool initialization (cached)
if command -v starship >/dev/null 2>&1; then
  _bash_eval_cache starship init bash
else
  PS1='\u@\h \W \$ '
fi

_bash_eval_cache zoxide init bash 2>/dev/null || true
_bash_eval_cache atuin init bash --disable-up-arrow 2>/dev/null || true
_bash_eval_cache fnm env --use-on-cd --shell bash 2>/dev/null || true
_bash_eval_cache rbenv init - --no-rehash bash 2>/dev/null || true

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

