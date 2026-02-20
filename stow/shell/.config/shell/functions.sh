# shellcheck shell=bash
# Prefer fd when available, otherwise fall back to find.
_list_files() {
    if command -v fd >/dev/null 2>&1; then
        fd --type f
    else
        find . -type f 2>/dev/null | sed 's#^\./##'
    fi
}

_developer_root() {
    printf '%s\n' "${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"
}

_project_search_roots() {
    local dev_root
    dev_root="$(_developer_root)"

    [[ -d "$dev_root" ]] || return 0

    # Discover project categories dynamically (e.g., personal/* and work/*).
    find "$dev_root"/personal "$dev_root"/work -mindepth 1 -maxdepth 1 -type d 2>/dev/null
}

_project_roots() {
    local roots
    roots="$(_project_search_roots)"
    [[ -n "$roots" ]] || return 0

    while read -r root; do
        [[ -d "$root" ]] || continue
        find "$root" -mindepth 1 -maxdepth 4 -name .git -type d 2>/dev/null | while read -r gitdir; do
            dirname "$gitdir"
        done
    done <<< "$roots"
}

_project_menu() {
    _project_roots | while read -r repo; do
        local ts rel date name scope display dev_root_rel
        ts=$(git -C "$repo" log -1 --format=%ct 2>/dev/null || true)
        [[ -n "$ts" ]] || ts=$(stat -f %m "$repo" 2>/dev/null || echo 0)
        rel="${repo/#$HOME\//~/}"
        name="$(basename "$repo")"
        dev_root_rel="$(_developer_root)"
        dev_root_rel="${dev_root_rel/#$HOME\//~/}"
        scope="$(echo "$rel" | sed -E "s#^$dev_root_rel/##; s#/[^/]+\$##")"
        date=$(date -r "$ts" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
        display="$(printf '%-28.28s  %-34.34s  %s' "$name" "$scope" "$date")"
        printf '%s\t%s\t%s\n' "$ts" "$repo" "$display"
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
        --delimiter=$'\t' --with-nth=2 \
        --header=$'name                         scope                              updated' \
        --preview 'repo=$(echo {} | cut -f1); echo "$repo"; echo ""; git -C "$repo" log -1 --oneline 2>/dev/null || echo "No commits"; echo ""; git -C "$repo" status --short 2>/dev/null | sed -n "1,20p"')
    [[ -n "$selected" ]] || return
    project=$(echo "$selected" | cut -f1)

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
devp() { cd "$(_developer_root)/personal/projects" || return; ls -la; }
deve() { cd "$(_developer_root)/personal/experiments" || return; ls -la; }
devl() { cd "$(_developer_root)/personal/learning" || return; ls -la; }
devw() { cd "$(_developer_root)/work" || return; ls -la; }
deva() { cd "$(_developer_root)/archive" || return; ls -la; }

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
    local basedir="$(_developer_root)/$category"
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
