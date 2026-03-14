# shellcheck shell=bash  # closest to zsh; shellcheck has no zsh mode
# Modern CLI replacements (guarded: fall back gracefully if tool missing)
if command -v bat >/dev/null 2>&1; then alias cat="bat"; fi
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --group-directories-first"
  alias la="eza -la --group-directories-first --header --smart-group --time-style=relative --color-scale=all"
  alias ll="eza -la --group-directories-first --header --smart-group --time-style=relative --color-scale=all --git"
  alias lt="eza --tree --level=2"
fi

# Git shortcuts
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph"
alias lg="lazygit"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Utility
alias resource="source ~/.zshrc"
alias paths='echo $PATH | tr ":" "\n"'
alias brewup="brew update && brew upgrade && brew cleanup"

# Development cleanup
alias clean-node='find . -name "node_modules" -type d -prune -exec rm -rf {} +'
alias clean-python='find . -name "__pycache__" -type d -prune -exec rm -rf {} +'
alias clean-rust='cargo clean 2>/dev/null; find . -name "target" -type d -prune -exec rm -rf {} +'
alias clean-go='go clean -cache'
alias clean-dotnet='dotnet clean 2>/dev/null; find . -name "bin" -o -name "obj" -type d -prune -exec rm -rf {} +'
alias clean-ds='find . -name ".DS_Store" -delete'

# Search
if command -v rg >/dev/null 2>&1; then alias grep="rg"; fi

# Neovim
if command -v nvim >/dev/null 2>&1; then
  alias vim="nvim"
  alias vi="nvim"
  alias v="nvim"
fi

# System monitor
if command -v btop >/dev/null 2>&1; then alias top="btop"; fi

# Docker cleanup (OrbStack)
alias dclean='docker system prune -af --volumes'

# Claude CLI
alias clauded="claude --dangerously-skip-permissions"
