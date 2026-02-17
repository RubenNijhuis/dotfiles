#!/usr/bin/env bash
# Doctor checks: editor tooling checks.

check_biome() {
  if $QUICK_MODE; then
    return
  fi

  printf '%sChecking Biome...%s\n\n' "${BLUE}" "${NC}"

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

  if [[ $issues -eq 0 ]]; then
    record_result "Biome" 0 "$details"
  else
    record_result "Biome" 1 "$details"
  fi
}
