# shellcheck shell=bash
# Navigation
alias ..="cd .."
alias ...="cd ../.."

# Modern CLI replacements
alias cat="bat"
alias ls="eza"
alias ll="eza -la --icons --git"
alias lt="eza --tree --level=2"

# Search
alias lookup="history | grep "

# Git shortcuts
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph"

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

# Docker cleanup (OrbStack)
alias dclean='docker system prune -af --volumes'
