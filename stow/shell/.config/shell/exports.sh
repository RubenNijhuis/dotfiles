# shellcheck shell=bash  # closest to zsh; shellcheck has no zsh mode
export DOTFILES_DEVELOPER_ROOT="${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}"
export DOTFILES_HOMEBREW_PREFIX="${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}"
export DOTFILES_LMSTUDIO_HOME="${DOTFILES_LMSTUDIO_HOME:-$HOME/.lmstudio}"
export DOTFILES_EDITOR="${DOTFILES_EDITOR:-nvim}"
export DOTFILES_OBSIDIAN_REPO_PATH="${DOTFILES_OBSIDIAN_REPO_PATH:-$DOTFILES_DEVELOPER_ROOT/personal/projects/obsidian-store}"
export DOTFILES_DOTNET_VERSION="${DOTFILES_DOTNET_VERSION:-8}"
export DOTFILES_SCREENSHOTS_PATH="${DOTFILES_SCREENSHOTS_PATH:-$HOME/Desktop/Screenshots}"

export EDITOR="$DOTFILES_EDITOR"
export VISUAL="$DOTFILES_EDITOR"
export LANG="en_US.UTF-8"
export BUN_INSTALL="$HOME/.bun"

# Rust
export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# Homebrew
export HOMEBREW_NO_ENV_HINTS=1

# eza
export EZA_ICON_SPACING=2
export EZA_ICONS_AUTO=1
export EZA_COLORS="ic=38;5;59"

# fzf — Tokyo Night
export FZF_DEFAULT_OPTS=" \
  --color=fg:#c0caf5,bg:#1a1b26,hl:#ff9e64 \
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#ff9e64 \
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff \
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
