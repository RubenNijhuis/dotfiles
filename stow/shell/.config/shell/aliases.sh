# shellcheck shell=bash
# Navigation
alias ..="cd .."
alias ...="cd ../.."

# Modern CLI replacements
alias cat="bat"
alias ls="eza --icons"
alias l="eza -la --icons"
alias la="eza -la --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --level=2 --icons"

# Search
alias lookup="history | grep "

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

# TypeScript
alias ts="tsx"

# Development cleanup
alias clean-node='find . -name "node_modules" -type d -prune -exec rm -rf {} +'
alias clean-python='find . -name "__pycache__" -type d -prune -exec rm -rf {} +'
alias clean-ds='find . -name ".DS_Store" -delete'

# Neovim
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# System monitor
alias top="btop"

# Docker cleanup (OrbStack)
alias dclean='docker system prune -af --volumes'
