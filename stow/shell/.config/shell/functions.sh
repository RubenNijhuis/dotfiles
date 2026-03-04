# shellcheck shell=bash  # closest to zsh; shellcheck has no zsh mode

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Find and edit file (combines fd + fzf + editor)
fe() {
    local file
    if command -v fd >/dev/null 2>&1; then
        file=$(fd --type f | fzf --preview 'bat --color=always {}')
    else
        file=$(find . -type f 2>/dev/null | sed 's#^\./##' | fzf --preview 'bat --color=always {}')
    fi
    [[ -n "$file" ]] && ${=EDITOR:-nvim} "${file}"
}

# Quick project launcher (fd + fzf)
proj() {
    local project dev_root
    dev_root="${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"

    if ! command -v fd >/dev/null 2>&1; then
        echo "fd is not installed."
        return 1
    fi

    # Find git repos, sort by most recently modified (commit timestamp)
    project=$(fd --type d --hidden --no-ignore --glob '.git' "$dev_root" --max-depth 5 \
        | sed 's|/\.git/*$||' \
        | while read -r dir; do
            ts=$(git -C "$dir" log -1 --format='%ct' 2>/dev/null || echo 0)
            printf '%s\t%s\n' "$ts" "$dir"
        done \
        | sort -t$'\t' -k1 -nr \
        | cut -f2 \
        | fzf --prompt='project> ' --height=80% --layout=reverse \
            --with-nth=-1 --delimiter='/' \
            --no-sort)
    [[ -n "$project" && -d "$project" ]] || return

    cd "${project}" || return

    local editor="${EDITOR:-nvim}"
    case "$editor" in
        vim|nvim|nano|vi|emacs) $editor . ;;
        *) $editor --new-window . ;;
    esac
}

# Create new project with template
newproj() {
    local name="$1"
    local type="${2:-experiment}"
    local category="${3:-personal}"
    local dev_root="${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"

    if [[ -z "$name" ]]; then
        echo "Usage: newproj <name> [type] [category]"
        echo "Types: experiment, project"
        echo "Categories: personal, work"
        return 1
    fi

    # Transform to kebab-case
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr ' ' '-')

    # Determine location
    local basedir="$dev_root/$category"
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
