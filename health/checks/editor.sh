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
    add_suggestion "Install Biome for the active project, not globally"
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
    add_suggestion "Apply the editor configuration: make nix-switch"
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
    add_suggestion "Apply the editor configuration: make nix-switch"
  fi

  local bootstrap
  bootstrap=$(sed -n 's/^local lazypath = "\(\/nix\/store\/[^" ]*\)"$/\1/p' "$HOME/.config/nvim/init.lua" 2>/dev/null)
  if [[ -n "$bootstrap" && -d "$bootstrap" ]]; then
    details+="Plugin manager: Nix-owned\n  "
  else
    details+="Plugin manager: Nix bootstrap missing\n  "
    issues=$((issues + 1))
    add_suggestion "Rebuild and activate the editor configuration: make nix-switch"
  fi

  local registry="$HOME/.config/nvim/nix-plugins.json"
  if [[ -f "$registry" ]] && command -v jq >/dev/null 2>&1; then
    local _name path invalid=0 count=0 parsers
    while IFS=$'\t' read -r _name path; do
      count=$((count + 1))
      if [[ "$path" != /nix/store/* || ! -d "$path" ]]; then
        invalid=$((invalid + 1))
      fi
    done < <(jq -r '.plugins | to_entries[] | [.key, .value] | @tsv' "$registry")
    parsers=$(jq -r '.parsers' "$registry")
    if [[ "$count" == 0 || "$parsers" != /nix/store/* || ! -d "$parsers/parser" || ! -d "$parsers/queries" ]]; then
      invalid=$((invalid + 1))
    fi
    details+="Declared plugins: $count Nix-owned; $invalid invalid paths\n  Parsers/queries: $parsers"
    [[ "$invalid" == 0 ]] || issues=$((issues + 1))
    record_issue_count_result "Neovim" "$issues" 1 "$details"
    return
  fi

  # Legacy generation: a lockfile alone cannot prove mutable checkouts match it.
  local lock="$HOME/.config/nvim/lazy-lock.json"
  local plugin_root="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
  local plugin commit actual missing=0 drift=0
  if command -v jq >/dev/null 2>&1 && jq -e 'type == "object"' "$lock" >/dev/null 2>&1; then
    while IFS=$'\t' read -r plugin commit; do
      [[ "$plugin" == lazy.nvim ]] && continue # Nix owns this dependency now.
      if [[ ! -d "$plugin_root/$plugin" ]]; then
        missing=$((missing + 1))
      else
        actual=$(git -C "$plugin_root/$plugin" rev-parse HEAD 2>/dev/null || true)
        [[ "$actual" == "$commit" ]] || drift=$((drift + 1))
      fi
    done < <(jq -r 'to_entries[] | [.key, .value.commit] | @tsv' "$lock")
    details+="Plugin graph (still local): $missing missing, $drift differ from declared lock"
    if [[ "$missing" != 0 || "$drift" != 0 ]]; then
      issues=$((issues + 1))
      add_suggestion "Migrate and test the plugin graph; do not blindly sync or delete existing checkouts"
    fi
  else
    details+="Plugin graph: cannot verify declared lock (requires jq)"
    issues=$((issues + 1))
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
    add_suggestion "Apply the terminal configuration: make nix-switch"
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
    add_suggestion "Apply the terminal configuration: make nix-switch"
  fi

  record_issue_count_result "Starship" "$issues" 1 "$details"
}
