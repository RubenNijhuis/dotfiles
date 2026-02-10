# Navigation
alias ..="cd .."
alias ...="cd ../.."

# Modern CLI replacements
alias cat="bat"
alias ls="eza"
alias ll="eza -la --icons --git"
alias lt="eza --tree --level=2"

# Search
alias lookup="history | grep"

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
