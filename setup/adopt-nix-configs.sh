#!/usr/bin/env bash
# Move a named, already-declared configuration set aside before Home Manager
# becomes its sole owner. Moves are recoverable: every original gains .pre-nix.
set -euo pipefail

profile="${1:-}"
if [[ "$profile" == "--help" || "$profile" == "-h" ]]; then
  echo "Usage: $0 {git|search|terminal|navigation|terminal-apps|editor|shell-modules|shell}"
  exit 0
fi

case "$profile" in
  git)
    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/git"
    if [[ ! -e "$config_dir/config" ]]; then
      echo "Nix Git config is not active at $config_dir/config." >&2
      echo "Run 'make nix-switch' successfully before adopting Git." >&2
      exit 1
    fi
    files=("$HOME/.gitconfig" "$HOME/.gitconfig-personal" "$HOME/.gitignore_global")
    ;;
  search)
    files=("$HOME/.config/ripgrep/ripgreprc" "$HOME/.config/bat/config")
    ;;
  terminal)
    files=("$HOME/.config/starship.toml" "$HOME/.config/atuin/config.toml")
    ;;
  navigation)
    files=(
      "$HOME/.config/tmux/tmux.conf"
      "$HOME/.config/yazi/yazi.toml"
      "$HOME/.config/yazi/keymap.toml"
      "$HOME/.config/yazi/theme.toml"
      "$HOME/.config/sesh/sesh.toml"
    )
    ;;
  terminal-apps)
    files=(
      "$HOME/.config/btop/btop.conf"
      "$HOME/.config/btop/themes/tokyo-night-custom.theme"
      "$HOME/.config/lazygit/config.yml"
      "$HOME/.config/eza/theme.yml"
    )
    ;;
  editor)
    files=("$HOME/.config/nvim")
    ;;
  shell-modules)
    files=(
      "$HOME/.config/shell/aliases.sh"
      "$HOME/.config/shell/exports.sh"
      "$HOME/.config/shell/functions.sh"
      "$HOME/.config/shell/path.sh"
    )
    ;;
  shell)
    files=(
      "$HOME/.zshrc"
      "$HOME/.bashrc"
      "$HOME/.zshenv"
      "$HOME/.profile"
      "$HOME/.bash_profile"
    )
    ;;
  *)
    echo "Usage: $0 {git|search|terminal|navigation|terminal-apps|editor|shell-modules|shell}" >&2
    exit 2
    ;;
esac

for source_file in "${files[@]}"; do
  [[ -e "$source_file" ]] || continue
  source_target="$(readlink "$source_file" 2>/dev/null || true)"
  if [[ "$source_target" == /nix/store/* ]]; then
    echo "Already Nix-owned: $source_file"
    continue
  fi
  backup_file="${source_file}.pre-nix"
  if [[ -e "$backup_file" ]]; then
    echo "Refusing to overwrite existing backup: $backup_file" >&2
    exit 1
  fi
  mv "$source_file" "$backup_file"
  echo "Preserved $source_file as $backup_file"
done

if [[ "$profile" == "git" ]]; then
  echo
  echo "Active global Git configuration:"
  git config --global --list --show-origin
fi

if [[ "$profile" == "navigation" && -d "$HOME/.tmux/plugins" ]]; then
  echo
  echo "Left existing TPM files in ~/.tmux/plugins untouched."
  echo "After verifying tmux plugins, remove that obsolete TPM directory manually."
fi
