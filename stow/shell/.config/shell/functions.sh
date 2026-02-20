# shellcheck shell=bash
# Prefer fd when available, otherwise fall back to find.
_list_files() {
    if command -v fd >/dev/null 2>&1; then
        fd --type f
    else
        find . -type f 2>/dev/null | sed 's#^\./##'
    fi
}

_list_project_dirs() {
    local roots=(
        "$HOME/Developer/personal/projects"
        "$HOME/Developer/personal/experiments"
        "$HOME/Developer/personal/learning"
        "$HOME/Developer/work/projects"
        "$HOME/Developer/work/clients"
    )

    if command -v fd >/dev/null 2>&1; then
        fd --type d --max-depth 4 . "${roots[@]}" 2>/dev/null
    else
        find "${roots[@]}" -mindepth 1 -maxdepth 4 -type d 2>/dev/null
    fi
}

_project_roots() {
    local roots=(
        "$HOME/Developer/personal/projects"
        "$HOME/Developer/personal/experiments"
        "$HOME/Developer/personal/learning"
        "$HOME/Developer/work/projects"
        "$HOME/Developer/work/clients"
    )

    find "${roots[@]}" -mindepth 1 -maxdepth 4 -name .git -type d 2>/dev/null | while read -r gitdir; do
        dirname "$gitdir"
    done
}

_project_menu() {
    _project_roots | while read -r repo; do
        local ts rel date
        ts=$(git -C "$repo" log -1 --format=%ct 2>/dev/null || true)
        [[ -n "$ts" ]] || ts=$(stat -f %m "$repo" 2>/dev/null || echo 0)
        rel="${repo/#$HOME\//~/}"
        date=$(date -r "$ts" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
        printf '%s\t%s\t%s\n' "$ts" "$date" "$rel"
    done | sort -t$'\t' -k1,1nr | cut -f2-
}

_sync_project_repo() {
    local repo="$1"
    local upstream behind

    git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

    git -C "$repo" fetch --prune --quiet 2>/dev/null || return 0

    # Pull only when clean and fast-forward is possible.
    if [[ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ]]; then
        upstream=$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
        if [[ -n "$upstream" ]]; then
            behind=$(git -C "$repo" rev-list --count HEAD.."$upstream" 2>/dev/null || echo 0)
            if [[ "$behind" -gt 0 ]]; then
                git -C "$repo" pull --ff-only --quiet 2>/dev/null || true
            fi
        fi
    fi
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Find and edit file (combines fd + fzf + editor)
fe() {
    local file
    file=$(_list_files | fzf --preview 'bat --color=always {}') && ${EDITOR} "${file}"
}

# Quick project launcher (recently active repos + sync + editor open)
proj() {
    local selected project
    # shellcheck disable=SC2016
    selected=$(_project_menu | fzf --prompt='project> ' --height=80% --layout=reverse \
        --preview 'repo=$(echo {} | awk "{print \$2}"); repo=${repo/#\~/$HOME}; echo "$repo"; echo ""; git -C "$repo" log -1 --oneline 2>/dev/null || echo "No commits"; echo ""; git -C "$repo" status --short 2>/dev/null | sed -n "1,20p"')
    [[ -n "$selected" ]] || return
    project=$(echo "$selected" | awk '{print $2}')
    project="${project/#\~/$HOME}"

    _sync_project_repo "$project"
    [[ -n "$project" ]] || return
    cd "${project}" || return

    if [[ -n "${EDITOR:-}" ]]; then
        sh -c "${EDITOR} \"$project\"" >/dev/null 2>&1 &
    elif command -v code >/dev/null 2>&1; then
        code "$project" >/dev/null 2>&1 &
    fi
}

project() { proj "$@"; }

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
