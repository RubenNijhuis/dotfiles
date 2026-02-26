#!/usr/bin/env bash
# Doctor checks: core environment and configuration checks.
CORE_CHECKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_CHECKS_DIR/../../lib/env.sh"
dotfiles_load_env "$(cd "$CORE_CHECKS_DIR/../../.." && pwd)"

developer_root() {
  printf '%s\n' "$DOTFILES_DEVELOPER_ROOT"
}

check_stow() {
  printf '%sChecking Stow Configuration...%s\n\n' "${BLUE}" "${NC}"

  local stow_dir="$DOTFILES/stow"

  if [[ ! -d "$stow_dir" ]]; then
    record_result "Stow Configuration" 2 "Stow directory not found at $stow_dir"
    add_suggestion "Ensure dotfiles are cloned correctly and stow/ exists"
    return
  fi

  # Expected packages
  local packages=(bat ghostty git gpg shell ssh vim vscode zsh)
  local symlinked=0
  local total=${#packages[@]}

  for pkg in "${packages[@]}"; do
    local pkg_dir="$stow_dir/$pkg"
    if [[ -d "$pkg_dir" ]]; then
      symlinked=$((symlinked + 1))
    fi
  done

  # Check for broken symlinks in home directory
  local broken_count=0
  while IFS= read -r link; do
    if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
      broken_count=$((broken_count + 1))
    fi
  done < <(find "$HOME" -maxdepth 1 -type l 2>/dev/null)

  if [[ $symlinked -eq $total ]] && [[ $broken_count -eq 0 ]]; then
    record_result "Stow Configuration" 0 "$symlinked/$total packages properly symlinked, no broken symlinks found"
  elif [[ $broken_count -gt 0 ]]; then
    record_result "Stow Configuration" 2 "Found $broken_count broken symlinks in home directory"
    add_suggestion "Run: make unstow && make stow to fix symlinks"
  else
    record_result "Stow Configuration" 2 "Only $symlinked/$total packages found"
    add_suggestion "Ensure all stow packages exist in $DOTFILES/stow/"
  fi
}

check_ssh() {
  printf '%sChecking SSH Configuration...%s\n\n' "${BLUE}" "${NC}"

  local issues=0
  local details=""

  # Check personal key
  if [[ -f "$HOME/.ssh/id_ed25519_personal" ]]; then
    local perms=$(stat -f "%OLp" "$HOME/.ssh/id_ed25519_personal" 2>/dev/null || echo "")
    if [[ "$perms" == "600" ]]; then
      details+="Personal key: ~/.ssh/id_ed25519_personal (600)\n  "
    else
      details+="Personal key: incorrect permissions ($perms, expected 600)\n  "
      issues=$((issues + 1))
      add_suggestion "Fix permissions: chmod 600 ~/.ssh/id_ed25519_personal"
    fi
  else
    details+="Personal key: missing\n  "
    issues=$((issues + 1))
    add_suggestion "Generate personal SSH key: make ssh-setup"
  fi

  # Check work key (optional - warning only)
  if [[ -f "$HOME/.ssh/id_ed25519_work" ]]; then
    local perms=$(stat -f "%OLp" "$HOME/.ssh/id_ed25519_work" 2>/dev/null || echo "")
    if [[ "$perms" == "600" ]]; then
      details+="Work key: ~/.ssh/id_ed25519_work (600)\n  "
    else
      details+="Work key: incorrect permissions ($perms, expected 600)\n  "
      issues=$((issues + 1))
      add_suggestion "Fix permissions: chmod 600 ~/.ssh/id_ed25519_work"
    fi
  else
    details+="⚠ Work key: not configured (optional)\n  "
  fi

  # Check SSH config includes
  if [[ -f "$HOME/.ssh/config" ]]; then
    if grep -q "Include" "$HOME/.ssh/config" 2>/dev/null; then
      local includes_count=$(find "$HOME/.ssh/config.d" -name "*.conf" 2>/dev/null | wc -l | xargs)
      details+="SSH config includes: $includes_count loaded"
    else
      details+="SSH config: Include directive missing"
      issues=$((issues + 1))
      add_suggestion "Re-stow SSH config: cd $DOTFILES && make stow"
    fi
  else
    details+="SSH config: missing"
    issues=$((issues + 1))
  fi

  # Check SSH agent (warning only)
  if ssh-add -l &>/dev/null; then
    local loaded_keys=$(ssh-add -l | wc -l | xargs)
    details+="\n  SSH agent: $loaded_keys keys loaded"
  else
    details+="\n  ⚠ SSH agent: no keys loaded"
    add_suggestion "Load SSH keys: ssh-add ~/.ssh/id_ed25519_personal ~/.ssh/id_ed25519_work"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "SSH Configuration" 0 "$details"
  else
    record_result "SSH Configuration" 2 "$details"
  fi
}

check_gpg() {
  printf '%sChecking GPG Configuration...%s\n' "${BLUE}" "${NC}"
  echo ""

  local issues=0
  local details=""

  # Check if GPG key exists
  if gpg --list-secret-keys &>/dev/null; then
    local key_id=$(gpg --list-secret-keys --keyid-format=long | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)
    details+="Secret key: $key_id\n  "
  else
    details+="No GPG secret key found\n  "
    issues=$((issues + 1))
    add_suggestion "Generate GPG key: make gpg-setup"
  fi

  # Check Git signing config
  if git config --global user.signingkey &>/dev/null; then
    details+="Git signing: enabled\n  "
  else
    details+="Git signing: not configured\n  "
    issues=$((issues + 1))
    add_suggestion "Configure GPG signing: make gpg-setup"
  fi

  # Test GPG sign (warning only)
  if ! echo "test" | gpg --clear-sign &>/dev/null; then
    details+="⚠ GPG test sign failed"
    add_suggestion "Check GPG agent: pkill gpg-agent && gpgconf --launch gpg-agent"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "GPG Configuration" 0 "$details"
  else
    record_result "GPG Configuration" 2 "$details"
  fi
}

check_git() {
  printf '%sChecking Git Configuration...%s\n' "${BLUE}" "${NC}"
  echo ""

  local issues=0
  local details=""

  # Check conditional includes exist in .gitconfig
  if [[ -f "$HOME/.gitconfig" ]]; then
    if grep -q "includeIf" "$HOME/.gitconfig"; then
      details+="Conditional includes: configured\n  "
    else
      details+="Conditional includes: missing from .gitconfig\n  "
      issues=$((issues + 1))
      add_suggestion "Re-stow git config: cd $DOTFILES && make stow"
    fi
  else
    details+="No .gitconfig found\n  "
    issues=$((issues + 1))
    add_suggestion "Re-stow git config: cd $DOTFILES && make stow"
  fi

  local dev_root
  dev_root="$(developer_root)"

  # Test in personal repo (if exists)
  if [[ -d "$dev_root/personal/projects/dotfiles/.git" ]]; then
    cd "$dev_root/personal/projects/dotfiles" || return 1
    local ssh_cmd=$(git config core.sshCommand || echo "")
    if [[ "$ssh_cmd" == *"id_ed25519_personal"* ]]; then
      details+="Personal repos: using id_ed25519_personal\n  "
    else
      details+="Personal repos: incorrect SSH key\n  "
      issues=$((issues + 1))
      add_suggestion "Check .gitconfig-personal conditional include"
    fi
  fi

  # Test in work repo (if exists)
  if [[ -d "$dev_root/work/clients" ]]; then
    local work_repo=$(find "$dev_root/work/clients" -name ".git" -type d | head -1)
    if [[ -n "$work_repo" ]]; then
      cd "$(dirname "$work_repo")" || return 1
      local ssh_cmd=$(git config core.sshCommand || echo "")
      if [[ "$ssh_cmd" == *"id_ed25519_work"* ]]; then
        details+="Work repos: using id_ed25519_work"
      else
        details+="Work repos: incorrect SSH key"
        issues=$((issues + 1))
        add_suggestion "Check .gitconfig-work conditional include"
      fi
    fi
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Git Configuration" 0 "$details"
  else
    record_result "Git Configuration" 2 "$details"
  fi
}

check_shell() {
  printf '%sChecking Shell Configuration...%s\n' "${BLUE}" "${NC}"
  echo ""

  local issues=0
  local details=""

  # Source shell config in subshell to check functions/aliases
  # We need to check if the config files exist and are properly linked
  local shell_files=(
    "$HOME/.zshrc"
    "$HOME/.config/shell/functions.sh"
    "$HOME/.config/shell/aliases.sh"
  )

  local missing_files=0
  for file in "${shell_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      missing_files=$((missing_files + 1))
    fi
  done

  if [[ $missing_files -eq 0 ]]; then
    details+="Shell config files: all present\n  "

    # Count functions defined in functions.sh
    local func_count=$(grep -c "^[a-z_]*() {" "$HOME/.config/shell/functions.sh" 2>/dev/null || echo "0")
    if [[ $func_count -gt 0 ]]; then
      details+="Functions: $func_count defined\n  "
    else
      details+="Functions: none found\n  "
      issues=$((issues + 1))
    fi

    # Count aliases defined in aliases.sh
    local alias_count=$(grep -c "^alias " "$HOME/.config/shell/aliases.sh" 2>/dev/null || echo "0")
    if [[ $alias_count -gt 0 ]]; then
      details+="Aliases: $alias_count defined\n  "
    else
      details+="Aliases: none found\n  "
      issues=$((issues + 1))
    fi
  else
    details+="Shell config files: $missing_files missing\n  "
    issues=$((issues + 1))
    add_suggestion "Re-stow shell config: cd $DOTFILES && make stow"
  fi

  # Check PATH
  local path_items=(fnm bun brew)
  local path_ok=true

  for item in "${path_items[@]}"; do
    if ! command -v "$item" &>/dev/null; then
      path_ok=false
      details+="⚠ $item not found in PATH\n  "
    fi
  done

  if $path_ok; then
    details+="PATH: fnm, Bun, Homebrew found"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Shell Configuration" 0 "$details"
  else
    record_result "Shell Configuration" 2 "$details"
  fi
}

check_developer() {
  printf '%sChecking Developer Directory...%s\n' "${BLUE}" "${NC}"
  echo ""

  local issues=0
  local warnings=0
  local details=""

  local dev_root
  dev_root="$(developer_root)"

  # Check structure exists
  local dirs=(
    "$dev_root/personal/projects"
    "$dev_root/personal/experiments"
    "$dev_root/personal/learning"
    "$dev_root/work/clients"
    "$dev_root/archive"
  )

  local missing=0
  for dir in "${dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      missing=$((missing + 1))
    fi
  done

  if [[ $missing -eq 0 ]]; then
    details+="Structure: complete\n  "
  else
    details+="Structure: $missing directories missing\n  "
    issues=$((issues + 1))
    add_suggestion "Create structure: mkdir -p \"$dev_root\"/{personal/{projects,experiments,learning},work/clients,archive}"
  fi

  # Count repos per category
  local total=$(find "$dev_root" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local personal_projects=$(find "$dev_root/personal/projects" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local personal_experiments=$(find "$dev_root/personal/experiments" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local personal_learning=$(find "$dev_root/personal/learning" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local work=$(find "$dev_root/work" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local archive=$(find "$dev_root/archive" -name ".git" -type d 2>/dev/null | wc -l | xargs)

  details+="Repositories: $total total\n  "
  details+="  - personal/projects: $personal_projects\n  "
  details+="  - personal/experiments: $personal_experiments\n  "
  details+="  - personal/learning: $personal_learning\n  "
  details+="  - work/clients: $work\n  "
  details+="  - archive: $archive"

  # Detect multiple unique dotfiles clones to prevent stow ownership conflicts.
  local canonical_paths=""
  local unique_count=0
  local candidate canonical
  for candidate in "$HOME/dotfiles" "$dev_root/personal/projects/dotfiles"; do
    if [[ -d "$candidate/.git" ]]; then
      canonical="$(cd "$candidate" 2>/dev/null && pwd -P || true)"
      if [[ -n "$canonical" ]] && ! grep -qxF "$canonical" <<< "$canonical_paths"; then
        canonical_paths+="${canonical}"$'\n'
        unique_count=$((unique_count + 1))
      fi
    fi
  done

  if [[ $unique_count -gt 1 ]]; then
    warnings=$((warnings + 1))
    details+="\n  ⚠ Multiple dotfiles clones detected:"
    while IFS= read -r canonical; do
      [[ -n "$canonical" ]] || continue
      details+="\n    - $canonical"
    done <<< "$canonical_paths"
    add_suggestion "Keep one clone only to avoid stow ownership conflicts"
  fi

  # Check old structure removed
  if [[ -d "$dev_root/repositories" ]]; then
    details+="\n  ⚠ Old repositories/ folder still exists"
    add_suggestion "Complete migration: make complete-migration"
  fi

  if [[ $issues -eq 0 ]] && [[ $warnings -gt 0 ]]; then
    record_result "Developer Directory" 1 "$details"
  elif [[ $issues -eq 0 ]]; then
    record_result "Developer Directory" 0 "$details"
  else
    record_result "Developer Directory" 2 "$details"
  fi
}

check_runtime() {
  printf '%sChecking Runtime Environments...%s\n' "${BLUE}" "${NC}"
  echo ""

  local details=""

  # Node.js via fnm
  if command -v node &>/dev/null; then
    local node_version=$(node --version)
    details+="Node.js: $node_version (via fnm)\n  "
  else
    details+="Node.js: not installed\n  "
    add_suggestion "Install Node.js: fnm install --lts"
  fi

  # Bun
  if command -v bun &>/dev/null; then
    local bun_version=$(bun --version)
    details+="Bun: $bun_version"
  else
    details+="Bun: not installed"
    add_suggestion "Install Bun: curl -fsSL https://bun.sh/install | bash"
  fi

  record_result "Runtime Environments" 0 "$details"
}
