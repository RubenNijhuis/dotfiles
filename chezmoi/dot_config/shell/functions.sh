# shellcheck shell=bash  # closest to zsh; shellcheck has no zsh mode

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Find and edit file (fd + fzf + editor)
fe() {
    local file
    file=$(fd --type f | fzf --preview 'bat --color=always {}')
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
    echo "Created $name in $target"
}

# Yazi file manager wrapper — cd into directory on exit
y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd" || return
    fi
    rm -f -- "$tmp"
}

# Force-refresh shell caches (completions + eval caches)
# Useful after brew install/upgrade to pick up new completions immediately.
flush-cache() {
    rm -f "${ZDOTDIR:-$HOME}/.zcompdump"*
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/bash"
    echo "Shell caches cleared. Restart your shell to rebuild."
}

# Guarded development cleanup
# Refuses to run at $HOME or / (catches "ran in the wrong place" mistakes).
# Refuses if more than 20 matches would be deleted (catches "ran one level
# too high"). Override the cap with FORCE=1.
_clean_guard() {
    case "$PWD" in
        "$HOME"|"/"|"$HOME/Developer"|"$DOTFILES_DEVELOPER_ROOT")
            echo "clean: refusing to run at $PWD" >&2
            return 1
            ;;
    esac
}

_clean_sweep() {
    local label="$1" pattern="$2"
    _clean_guard || return 1
    local matches
    matches=$(fd --hidden --no-ignore --type d --glob "$pattern" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$matches" -eq 0 ]]; then
        echo "clean-$label: nothing to remove."
        return 0
    fi
    if [[ "$matches" -gt 20 && "${FORCE:-0}" != "1" ]]; then
        echo "clean-$label: $matches matches under $PWD — refusing (set FORCE=1 to override)." >&2
        return 1
    fi
    fd --hidden --no-ignore --type d --glob "$pattern" -X rm -rf
    echo "clean-$label: removed $matches dir(s)."
}

clean-node()    { _clean_sweep node "node_modules"; }
clean-python()  { _clean_sweep python "__pycache__"; }
clean-rust()    { _clean_guard || return 1; cargo clean 2>/dev/null; _clean_sweep rust "target"; }
clean-go()      { go clean -cache; }
clean-dotnet()  {
    _clean_guard || return 1
    dotnet clean 2>/dev/null
    local matches
    matches=$(fd --hidden --no-ignore --type d --glob '{bin,obj}' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$matches" -gt 20 && "${FORCE:-0}" != "1" ]]; then
        echo "clean-dotnet: $matches matches under $PWD — refusing (set FORCE=1 to override)." >&2
        return 1
    fi
    fd --hidden --no-ignore --type d --glob '{bin,obj}' -X rm -rf
    echo "clean-dotnet: removed $matches dir(s)."
}
clean-ds() {
    _clean_guard || return 1
    fd --hidden --type f -g .DS_Store -X rm -f
}
