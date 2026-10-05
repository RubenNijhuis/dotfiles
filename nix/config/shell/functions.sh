# shellcheck shell=bash
# Nix-owned; closest to zsh, which ShellCheck does not support directly.

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

# Optional, Nix-owned platform integration (absent on Linux/WSL).
# shellcheck disable=SC1091
[[ ! -f "$HOME/.config/shell/cmux.sh" ]] || source "$HOME/.config/shell/cmux.sh"

# Choose a repository, or open an explicit directory. Worktrees use .git files.
proj() {
    local project dev_root dir ts editor
    if [[ $# -gt 1 || "${1:-}" == "--help" ]]; then
        echo "Usage: proj [directory]"
        return 0
    fi
    if [[ $# -eq 1 ]]; then
        project="$1"
    else
        dev_root="${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"
        if ! command -v fd >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
            echo "proj: fd and fzf are required for the picker." >&2
            return 1
        fi
        project=$(fd --hidden --no-ignore --type d --type f --glob '.git' \
            --prune --max-depth 6 "$dev_root" \
            | sed 's|/\.git/*$||' \
            | while IFS= read -r dir; do
                ts=$(git -C "$dir" log -1 --format='%ct' 2>/dev/null) || ts=0
                printf '%s\t%s\n' "$ts" "$dir"
            done \
            | sort -t$'\t' -k1 -nr \
            | cut -f2- \
            | fzf --prompt='project> ' --height=80% --layout=reverse --no-sort)
        [[ -n "$project" ]] || return 0
    fi
    if [[ ! -d "$project" ]]; then
        printf 'proj: directory not found: %s\n' "$project" >&2
        return 1
    fi
    project=$(builtin cd -- "$project" && pwd -P) || return
    if [[ -n "${CMUX_WORKSPACE_ID:-}" ]] && command -v cmux >/dev/null 2>&1; then
        cmux new-workspace --cwd "$project" --name "${project##*/}" --focus true
        return $?
    fi
    builtin cd -- "$project" || return
    editor="${EDITOR:-nvim}"
    case "$editor" in
        vim|nvim|nano|vi|emacs) "$editor" . ;;
        *) "$editor" --new-window . ;;
    esac
}

# Explicit completion notifications; preserve the command's arguments and status.
notify-run() {
    local result label
    if [[ $# -eq 0 ]]; then
        echo "Usage: notify-run command [arguments...]" >&2
        return 2
    fi
    label="${1##*/}"
    if "$@"; then result=0; else result=$?; fi
    if [[ -n "${CMUX_WORKSPACE_ID:-}" ]] && command -v cmux >/dev/null 2>&1; then
        # Avoid copying arguments (which can contain secrets) into notifications.
        cmux notify --title "$label finished" --body "Exit status: $result" \
            >/dev/null 2>&1 || true
    fi
    return "$result"
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

# Force-refresh shell caches (completions + eval caches).
flush-cache() {
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
clean-ds() {
    _clean_guard || return 1
    fd --hidden --type f -g .DS_Store -X rm -f
}
