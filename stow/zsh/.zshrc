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

# ----- Completion UI -----
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{6}%d%f'
zstyle ':completion:*:messages' format '%F{3}%d%f'
zstyle ':completion:*:warnings' format '%F{1}No matches for: %d%f'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
else
  zstyle ':completion:*' list-colors 'di=1;36:ln=35:ex=32'
fi

# Keep `cd` completion focused on local/named directories, not broad path sources.
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack named-directories
zstyle ':completion:*:*:cd:*' list-colors 'di=1;36'

# ----- History -----
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
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

# ----- Tool initialization (eval outputs cached per binary) -----
# Cache is stored in $XDG_CACHE_HOME/zsh/ and invalidated when the binary changes.
_zsh_eval_cache() {
  local cmd="$1"
  local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${cmd}.zsh"
  if [[ ! -f "$cache_file" ]] || [[ "$(command -v "$cmd")" -nt "$cache_file" ]]; then
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    "$@" > "$cache_file"
  fi
  source "$cache_file"
}

_zsh_eval_cache fnm env --use-on-cd --shell zsh
_zsh_eval_cache zoxide init zsh
# Load fzf key bindings without replacing Tab completion.
if [[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
fi
if [[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
fi
if command -v atuin >/dev/null 2>&1; then
  _zsh_eval_cache atuin init zsh --disable-up-arrow
fi
if command -v gh >/dev/null 2>&1; then
  _zsh_eval_cache gh completion -s zsh
fi

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

if command -v docker >/dev/null 2>&1; then
  _zsh_eval_cache docker completion zsh
fi

# OrbStack (optional; only present when OrbStack is installed)
[[ -f ~/.orbstack/shell/init.zsh ]] && source ~/.orbstack/shell/init.zsh

# ----- Shell config modules -----
source ~/.config/shell/path.sh
source ~/.config/shell/exports.sh
source ~/.config/shell/aliases.sh
source ~/.config/shell/functions.sh

# ----- Prompt -----
if command -v starship >/dev/null 2>&1; then
  _zsh_eval_cache starship init zsh
else
  PROMPT='%n@%m %1~ %# '
fi

# ----- Local overrides (not committed) -----
[[ -f ~/.config/shell/local.sh ]] && source ~/.config/shell/local.sh

# Final keybinding override: keep Tab on standard completion.
bindkey -M emacs '^I' expand-or-complete
bindkey -M viins '^I' expand-or-complete

# Ensure clean exit code
return 0 2>/dev/null || true
