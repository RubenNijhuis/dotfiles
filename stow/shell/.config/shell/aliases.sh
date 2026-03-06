# shellcheck shell=bash  # closest to zsh; shellcheck has no zsh mode
# Modern CLI replacements
alias cat="bat"
alias ls="eza --group-directories-first"
alias la="eza -la --group-directories-first --header --smart-group --time-style=relative --color-scale=all"
alias ll="eza -la --group-directories-first --header --smart-group --time-style=relative --color-scale=all --git"
alias lt="eza --tree --level=2"

# Git shortcuts
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph"
alias lg="lazygit"

# Utility
alias resource="source ~/.zshrc"
alias paths='echo $PATH | tr ":" "\n"'
alias brewup="brew update && brew upgrade && brew cleanup"

# Development cleanup
alias clean-node='find . -name "node_modules" -type d -prune -exec rm -rf {} +'
alias clean-python='find . -name "__pycache__" -type d -prune -exec rm -rf {} +'
alias clean-ds='find . -name ".DS_Store" -delete'

# Search
alias grep="rg"

# Neovim
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# System monitor
alias top="btop"

# Docker cleanup (OrbStack)
alias dclean='docker system prune -af --volumes'
