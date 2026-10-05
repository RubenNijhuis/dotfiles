#!/usr/bin/env bash
# Move a named, already-declared configuration set aside before Home Manager
# becomes its sole owner. Moves are recoverable: every original gains .pre-nix.
set -euo pipefail

profile="${1:-}"
usage="Usage: $0 {git|ssh-gpg|spicetify|search|terminal|cmux|navigation|terminal-apps|editor|shell-modules|shell} [--dry-run]"
if [[ "$profile" == "--help" || "$profile" == "-h" ]]; then
  echo "$usage"
  exit 0
fi
dry_run=false
if [[ $# -gt 2 || ( $# -eq 2 && "$2" != --dry-run ) ]]; then
  echo "$usage" >&2
  exit 2
fi
[[ "${2:-}" != --dry-run ]] || dry_run=true

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
  ssh-gpg)
    files=(
      "$HOME/.ssh/config"
      "$HOME/.ssh/config.d/common.conf"
      "$HOME/.ssh/config.d/personal.conf"
      "$HOME/.gnupg/gpg.conf"
      "$HOME/.gnupg/gpg-agent.conf"
    )
    ;;
  spicetify)
    files=(
      "$HOME/.config/spicetify/Themes/TokyoNight/color.ini"
      "$HOME/.config/spicetify/Themes/TokyoNight/user.css"
    )
    ;;
  search)
    files=(
      "$HOME/.config/ripgrep/ripgreprc"
      "$HOME/.config/bat/config"
      "$HOME/.config/bat/themes/tokyonight_night.tmTheme"
    )
    ;;
  terminal)
    files=("$HOME/.config/starship.toml" "$HOME/.config/atuin/config.toml")
    ;;
  cmux)
    files=("$HOME/.config/ghostty/config" "$HOME/.config/cmux/cmux.json")
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
    echo "$usage" >&2
    exit 2
    ;;
esac

# Preflight every target before moving any file; a later backup collision must
# not leave an earlier target partially adopted. Broken symlinks count as files.
pending=()
for source_file in "${files[@]}"; do
  [[ -e "$source_file" || -L "$source_file" ]] || continue
  source_target="$(readlink "$source_file" 2>/dev/null || true)"
  if [[ "$source_target" == /nix/store/* ]]; then
    echo "Already Nix-owned: $source_file"
    continue
  fi
  backup_file="${source_file}.pre-nix"
  if [[ -e "$backup_file" || -L "$backup_file" ]]; then
    echo "Refusing to overwrite existing backup: $backup_file" >&2
    exit 1
  fi
  pending+=("$source_file")
done

for source_file in "${pending[@]}"; do
  if "$dry_run"; then
    echo "Would preserve $source_file as ${source_file}.pre-nix"
  else
    mv "$source_file" "${source_file}.pre-nix"
    echo "Preserved $source_file as ${source_file}.pre-nix"
  fi
done
"$dry_run" && exit 0

if [[ "$profile" == "git" ]]; then
  echo
  echo "Active global Git configuration:"
  git -C / config --show-origin --get-regexp '^(user\.|includeIf\.)'
fi

if [[ "$profile" == "navigation" && -d "$HOME/.tmux/plugins" ]]; then
  echo
  echo "Left existing TPM files in ~/.tmux/plugins untouched."
  echo "After verifying tmux plugins, remove that obsolete TPM directory manually."
fi
