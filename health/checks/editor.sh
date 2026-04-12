#!/usr/bin/env bash
# Doctor checks: editor tooling checks.

check_biome() {
  if $QUICK_MODE; then
    return
  fi


  local issues=0
  local details=""
  local dotfiles_dir="$DOTFILES"

  if [[ ! -f "$dotfiles_dir/biome.json" ]]; then
    details+="Config: biome.json missing\n  "
    issues=$((issues + 1))
    add_suggestion "Biome config missing - ensure biome.json exists"
  else
    details+="Config: biome.json found\n  "
  fi

  if command -v biome &>/dev/null; then
    local biome_version=$(biome --version 2>/dev/null)
    details+="Biome: $biome_version"
  else
    details+="Biome: not installed"
    issues=$((issues + 1))
    add_suggestion "Install Biome: brew install biome"
  fi

  record_issue_count_result "Biome" "$issues" 1 "$details"
}

check_neovim() {
  if $QUICK_MODE; then
    return
  fi


  local issues=0
  local details=""

  if ! command -v nvim &>/dev/null; then
    record_result "Neovim" 1 "Neovim not installed"
    add_suggestion "Install Neovim: brew install neovim"
    return
  fi

  local nvim_version
  nvim_version=$(nvim --version 2>/dev/null | head -1)
  details+="$nvim_version\n  "

  # Check config exists
  if [[ -f "$HOME/.config/nvim/init.lua" ]]; then
    details+="Config: ~/.config/nvim/init.lua\n  "
  else
    details+="Config: missing\n  "
    issues=$((issues + 1))
    add_suggestion "Re-stow neovim config: cd $DOTFILES && make stow"
  fi

  # Check lazy.nvim plugin manager
  if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
    local plugin_count
    plugin_count=$(find "$HOME/.local/share/nvim/lazy" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | xargs)
    details+="Plugins: $plugin_count installed (lazy.nvim)\n  "
  else
    details+="Plugins: lazy.nvim not bootstrapped\n  "
    issues=$((issues + 1))
    add_suggestion "Open nvim to bootstrap lazy.nvim plugin manager"
  fi

  # Check for lazy-lock.json (ensures reproducible installs)
  if [[ -f "$HOME/.config/nvim/lazy-lock.json" ]]; then
    details+="Lock file: present"
  else
    details+="Lock file: missing"
    issues=$((issues + 1))
    add_suggestion "Run :Lazy sync in nvim to generate lazy-lock.json"
  fi

  record_issue_count_result "Neovim" "$issues" 1 "$details"
}

check_starship() {
  if $QUICK_MODE; then
    return
  fi

  local details=""
  local issues=0

  if ! command -v starship &>/dev/null; then
    record_result "Starship" 1 "Starship not installed"
    add_suggestion "Install Starship: brew install starship"
    return
  fi

  local starship_version
  starship_version=$(starship --version 2>/dev/null | head -1)
  details+="$starship_version\n  "

  if [[ -f "$HOME/.config/starship.toml" ]]; then
    details+="Config: ~/.config/starship.toml\n  "

    # Validate config is non-empty and contains expected content
    if grep -q "format" "$HOME/.config/starship.toml" 2>/dev/null; then
      details+="Config: valid"
    else
      details+="Config: could not validate"
      issues=$((issues + 1))
    fi
  else
    details+="Config: missing"
    issues=$((issues + 1))
    add_suggestion "Re-stow starship config: cd $DOTFILES && make stow"
  fi

  record_issue_count_result "Starship" "$issues" 1 "$details"
}
