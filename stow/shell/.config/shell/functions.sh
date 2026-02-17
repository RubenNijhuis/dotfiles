# shellcheck shell=bash
# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Find and edit file (combines fd + fzf + editor)
fe() {
    local file
    file=$(fd --type f | fzf --preview 'bat --color=always {}') && ${EDITOR} "${file}"
}

# Quick project switcher (searches ~/Developer with fd + fzf)
proj() {
    local project
    project=$(fd --type d --max-depth 4 . \
        ~/Developer/personal/projects \
        ~/Developer/personal/experiments \
        ~/Developer/personal/learning \
        ~/Developer/work/projects \
        ~/Developer/work/clients \
        2>/dev/null | fzf --preview 'echo {} && echo "" && git -C {} log -1 --oneline 2>/dev/null || echo "Not a git repo"') \
    && cd "${project}" || return
}

# Category-specific shortcuts
devp() { cd ~/Developer/personal/projects || return; ls -la; }
deve() { cd ~/Developer/personal/experiments || return; ls -la; }
devl() { cd ~/Developer/personal/learning || return; ls -la; }
devw() { cd ~/Developer/work || return; ls -la; }
deva() { cd ~/Developer/archive || return; ls -la; }

# Create new project with template
newproj() {
    local name="$1"
    local type="${2:-experiment}"
    local category="${3:-personal}"

    if [[ -z "$name" ]]; then
        echo "Usage: newproj <name> [type] [category]"
        echo "Types: experiment, project"
        echo "Categories: personal, work"
        return 1
    fi

    # Transform to kebab-case
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr ' ' '-')

    # Determine location
    local basedir="$HOME/Developer/$category"
    if [[ "$type" == "experiment" ]]; then
        local target="$basedir/experiments/$name"
    else
        local target="$basedir/projects/$name"
    fi

    mkdir -p "$target"
    cd "$target" || return
    git init
    echo "# $name" > README.md
    git add README.md
    git commit -m "Initial commit"
    echo "✓ Created $name in $target"
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
