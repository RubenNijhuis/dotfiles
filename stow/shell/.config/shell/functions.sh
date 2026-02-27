# shellcheck shell=bash
# Prefer fd when available, otherwise fall back to find.
dotfiles_list_files() {
    if command -v fd >/dev/null 2>&1; then
        fd --type f
    else
        find . -type f 2>/dev/null | sed 's#^\./##'
    fi
}

dotfiles_developer_root() {
    printf '%s\n' "${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Find and edit file (combines fd + fzf + editor)
fe() {
    local file
    file=$(dotfiles_list_files | fzf --preview 'bat --color=always {}') && ${EDITOR} "${file}"
}

# Quick project launcher (ghq + fzf)
proj() {
    local project
    if ! command -v ghq >/dev/null 2>&1; then
        echo "ghq is not installed."
        return 1
    fi

    # shellcheck disable=SC2016
    project=$(ghq list -p 2>/dev/null | fzf --prompt='project> ' --height=80% --layout=reverse \
        --preview 'repo={}; echo "repo: $repo"; git -C "$repo" log -1 --oneline 2>/dev/null || echo "last commit: none"; changes=$(git -C "$repo" status --short 2>/dev/null | sed -n "1,20p"); if [[ -n "$changes" ]]; then echo "$changes"; else echo "working tree: clean"; fi')
    [[ -n "$project" && -d "$project" ]] || return

    cd "${project}" || return

    if [[ -n "${EDITOR:-}" ]]; then
        sh -c "${EDITOR} \"$project\"" >/dev/null 2>&1 &
    elif command -v code >/dev/null 2>&1; then
        code "$project" >/dev/null 2>&1 &
    fi
}

project() { proj "$@"; }

projf() {
    if command -v zi >/dev/null 2>&1; then
        zi "$@"
        return
    fi
    echo "zi (zoxide) is not available."
    return 1
}

# Category-specific shortcuts
devp() { cd "$(dotfiles_developer_root)/personal/projects" || return; ls -la; }
deve() { cd "$(dotfiles_developer_root)/personal/experiments" || return; ls -la; }
devl() { cd "$(dotfiles_developer_root)/personal/learning" || return; ls -la; }
devw() { cd "$(dotfiles_developer_root)/work" || return; ls -la; }
deva() { cd "$(dotfiles_developer_root)/archive" || return; ls -la; }

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
    local basedir="$(dotfiles_developer_root)/$category"
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
