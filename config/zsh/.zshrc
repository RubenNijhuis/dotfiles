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
zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${zcompdump}(#qNmh-20) ]]; then
  # Cached: use existing dump from last 20 hours
  compinit -C -d "$zcompdump"
else
  # Expired: regenerate dump
  compinit -d "$zcompdump"
fi
unsetopt EXTENDEDGLOB

# fzf-tab: replaces menu-select with FZF fuzzy picker for completions.
# Must be sourced after compinit and before any zstyle ':fzf-tab:*' rules.
if [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

# ----- Completion UI -----
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
else
  zstyle ':completion:*' list-colors 'di=1;36:ln=35:ex=32'
fi

# Keep `cd` completion focused on local/named directories, not broad path sources.
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack named-directories
zstyle ':completion:*:*:cd:*' list-colors 'di=1;36'

# ----- fzf-tab config -----
# Inherit Tokyo Night colors from FZF_DEFAULT_OPTS; set layout and border.
zstyle ':fzf-tab:*' fzf-flags --height=50% --layout=reverse --border --select-1 --exit-0
# Use < and > to switch between completion groups (e.g. files vs commands).
zstyle ':fzf-tab:*' switch-group '<' '>'
# Preview directory contents with eza when completing cd.
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --color=always $realpath 2>/dev/null'

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
setopt GLOB_DOTS

# ----- Hooks -----
chpwd() { [[ -t 1 ]] && emulate -L zsh -o aliases && ls; }

# ----- Plugins (from Homebrew, cached paths) -----
[[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$HOMEBREW_PREFIX/share/zsh-you-should-use/you-should-use.plugin.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-you-should-use/you-should-use.plugin.zsh"
export YSU_MESSAGE_POSITION="after"

# Syntax highlighting (must be sourced synchronously — subshells can't modify parent)
[[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ----- Tool initialization (eval outputs cached per binary) -----
# Cache is stored in $XDG_CACHE_HOME/zsh/ and invalidated when the binary changes.
_zsh_eval_cache() {
  local cmd="$1"
  local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${cmd}.zsh"
  if [[ ! -f "$cache_file" ]] || [[ "$(command -v "$cmd")" -nt "$cache_file" ]]; then
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    "$@" > "$cache_file"
    if [[ ! -s "$cache_file" ]]; then
      rm -f "$cache_file"
      echo "[eval-cache] warning: ${cmd} produced empty output" >&2
      return 1
    fi
  fi
  source "$cache_file"
}

# ----- Lazy-loaded tools (deferred until first use) -----
_zsh_lazy_load_mise() {
  unfunction mise node npm npx corepack ruby gem bundle 2>/dev/null
  _zsh_eval_cache mise activate zsh
}
for cmd in mise node npm npx corepack ruby gem bundle; do
  eval "${cmd}() { _zsh_lazy_load_mise; ${cmd} \"\$@\" }"
done
unset cmd

_zsh_lazy_load_zoxide() {
  unfunction z zi __zoxide_z __zoxide_zi 2>/dev/null
  _zsh_eval_cache zoxide init zsh
}
for cmd in z zi; do
  eval "${cmd}() { _zsh_lazy_load_zoxide; ${cmd} \"\$@\" }"
done
unset cmd

_zsh_lazy_load_rustup() {
  unfunction rustup cargo rustc 2>/dev/null
  if command -v rustup >/dev/null 2>&1; then
    _zsh_eval_cache rustup completions zsh
  fi
}
for cmd in rustup cargo rustc; do
  eval "${cmd}() { _zsh_lazy_load_rustup; ${cmd} \"\$@\" }"
done
unset cmd
# Go, Zig, Cargo completions: auto-loaded by compinit via Homebrew site-functions
# Load fzf key bindings (Ctrl-R, Ctrl-T, Alt-C); Tab is handled by fzf-tab.
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

# Ensure clean exit code
return 0 2>/dev/null || true

