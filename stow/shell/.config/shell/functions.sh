# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and edit file (combines fd + fzf + editor)
fe() {
    local file
    file=$(fd --type f | fzf --preview 'bat --color=always {}') && ${EDITOR} "${file}"
}

# Quick project switcher (uses ~/personal and ~/work)
proj() {
    local project
    project=$(fd --type d --max-depth 2 . ~/personal ~/work 2>/dev/null | fzf) && cd "${project}"
}

# Git branch checkout with fzf
fco() {
    local branch
    branch=$(git branch -a | fzf | tr -d '[:space:]') && git checkout "${branch}"
}

# Colored man pages (replaces oh-my-zsh colored-man-pages plugin)
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'
