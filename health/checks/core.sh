#!/usr/bin/env bash
# Doctor checks: core environment and configuration checks.
CORE_CHECKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_CHECKS_DIR/../../lib/env.sh"
source "$CORE_CHECKS_DIR/../../lib/common.sh"
dotfiles_load_env "$(cd "$CORE_CHECKS_DIR/../.." && pwd)"

developer_root() {
  printf '%s\n' "$DOTFILES_DEVELOPER_ROOT"
}

# Find .git directories under a path, pruning heavy/unrelated trees.
# Constraints: max depth 5, skip node_modules/vendor/.build/Pods/.git/modules.
# Returns paths to .git dirs/files; safe to wc -l.
find_git_dirs() {
  local root="$1"
  [[ -d "$root" ]] || return 0
  find "$root" -maxdepth 5 \
    \( -name node_modules -o -name vendor -o -name .build -o -name Pods -o -path '*/.git/modules' \) -prune -o \
    -name .git -print 2>/dev/null
}

check_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    record_result "Nix" 1 "not installed"
    add_suggestion "Bootstrap Nix: make install"
    return
  fi
  local generation
  for generation in /run/current-system "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"; do
    if [[ -L "$generation" && -d "$generation" ]]; then
      record_result "Nix" 0 "active generation: $generation"
      return
    fi
  done
  record_result "Nix" 1 "installed; no active system/Home Manager generation found"
  add_suggestion "Build and activate the correct host: make nix-switch or make nix-home-switch"
}

check_ssh() {

  local issues=0
  local details=""

  # Check personal key
  if [[ -f "$HOME/.ssh/id_ed25519_personal" ]]; then
    local perms
    perms=$(file_mode "$HOME/.ssh/id_ed25519_personal" 2>/dev/null || echo "")
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

  # Check SSH config includes
  if [[ -f "$HOME/.ssh/config" ]]; then
    if grep -q "Include" "$HOME/.ssh/config" 2>/dev/null; then
      local includes_count
      includes_count=$(find "$HOME/.ssh/config.d" -name "*.conf" 2>/dev/null | wc -l | xargs)
      details+="SSH config includes: $includes_count loaded"
    else
      details+="SSH config: Include directive missing"
      issues=$((issues + 1))
      add_suggestion "Review SSH ownership and adoption before running make nix-switch"
    fi
  else
    details+="SSH config: missing"
    issues=$((issues + 1))
  fi

  # Check SSH agent (warning only)
  if ssh-add -l &>/dev/null; then
    local loaded_keys
    loaded_keys=$(ssh-add -l | wc -l | xargs)
    details+="\n  SSH agent: $loaded_keys keys loaded"
  else
    details+="\n  ⚠ SSH agent: no keys loaded"
    add_suggestion "Load SSH keys: ssh-add ~/.ssh/id_ed25519_personal"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "SSH Configuration" 0 "$details"
  else
    record_result "SSH Configuration" 2 "$details"
  fi
}

check_gpg() {

  # SSH signing is already a complete Git signing choice. Do not demand a
  # second identity or invoke the unrelated GPG keyring/signing machinery.
  if [[ "$(git -C / config --get gpg.format 2>/dev/null || true)" == ssh ]]; then
    record_result "GPG Configuration" 0 "Git uses SSH signing; GPG is not required for Git"
    return
  fi

  local gpg_pref
  gpg_pref="$(get_preference "PREF_SETUP_GPG")"
  if [[ "$gpg_pref" == "no" ]]; then
    record_result "GPG Configuration" 0 "${DIM}GPG: skipped (preference)${NC}"
    return
  fi

  local signing_key gpg_bin
  signing_key="$(git -C / config --get user.signingkey 2>/dev/null || true)"
  gpg_bin="$(git -C / config --get gpg.program 2>/dev/null || true)"
  gpg_bin="${gpg_bin:-gpg}"
  if [[ -z "$signing_key" ]]; then
    record_result "GPG Configuration" 1 "No signing identity selected"
    add_suggestion "Choose a signing identity before configuring Git signing"
    return
  fi

  # Resolve the same executable and selected key as Git, not an arbitrary key
  # or only ~/.gitconfig. Metadata only: never sign or request a passphrase in doctor.
  if ! command -v "$gpg_bin" >/dev/null 2>&1; then
    record_result "GPG Configuration" 2 "Configured GPG executable is unavailable"
    add_suggestion "Restore the declared GnuPG package with make nix-switch"
    return
  fi
  if ! "$gpg_bin" --batch --no-tty --with-colons --list-secret-keys "$signing_key" 2>/dev/null | grep -q '^sec:'; then
    record_result "GPG Configuration" 2 "Selected signing key is not available on this device"
    add_suggestion "Restore/provision the selected private key securely; Nix does not contain it"
    return
  fi

  local details="Selected signing key: available\n  Git uses OpenPGP signing"
  local issues=0
  local agent_config="${GNUPGHOME:-$HOME/.gnupg}/gpg-agent.conf"
  if [[ -f "$agent_config" ]]; then
    local pinentry_path
    pinentry_path=$(grep "^pinentry-program" "$agent_config" 2>/dev/null | awk '{print $2}')
    if [[ -n "$pinentry_path" ]] && [[ ! -x "$pinentry_path" ]]; then
      details+="\n  Pinentry is unavailable"
      issues=$((issues + 1))
      add_suggestion "Restore the declared pinentry package for this platform"
    fi
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "GPG Configuration" 0 "$details"
  else
    record_result "GPG Configuration" 2 "$details"
  fi
}

check_git() {

  local issues=0
  local details=""

  # Resolve both ~/.gitconfig and the XDG config, outside any repository.
  # --global alone selects ~/.gitconfig when it exists and misses XDG settings.
  if git -C / config --get user.email >/dev/null 2>&1; then
    if git -C / config --get-regexp '^includeIf\..*\.path$' >/dev/null 2>&1; then
      details+="Conditional includes: configured\n  "
    else
      details+="Conditional includes: missing from resolved Git config\n  "
      issues=$((issues + 1))
      add_suggestion "Apply Git configuration: make nix-switch"
    fi
  else
    details+="No global Git configuration found\n  "
    issues=$((issues + 1))
    add_suggestion "Apply Git configuration: make nix-switch"
  fi

  local dev_root
  dev_root="$(developer_root)"

  # Test in personal repo (if exists)
  local personal_dotfiles=""
  for candidate in "$dev_root/personal/dotfiles" "$dev_root/personal/projects/dotfiles"; do
    if [[ -d "$candidate/.git" ]]; then
      personal_dotfiles="$candidate"
      break
    fi
  done
  if [[ -n "$personal_dotfiles" ]]; then
    local ssh_cmd
    ssh_cmd=$(git -C "$personal_dotfiles" config core.sshCommand || echo "")
    if [[ "$ssh_cmd" == *"id_ed25519_personal"* ]]; then
      details+="Personal repos: using id_ed25519_personal\n  "
    else
      details+="Personal repos: incorrect SSH key\n  "
      issues=$((issues + 1))
      add_suggestion "Check .gitconfig-personal conditional include"
    fi
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Git Configuration" 0 "$details"
  else
    record_result "Git Configuration" 2 "$details"
  fi
}

check_shell() {

  local issues=0
  local details=""

  # Source shell config in subshell to check functions/aliases
  # Home Manager sets ZDOTDIR, so its Zsh startup file intentionally lives in
  # ~/.config/zsh/.zshrc instead of ~/.zshrc.
  local shell_files=(
    "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc"
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
    local func_count
    func_count=$(grep -c "^[a-z_]*() {" "$HOME/.config/shell/functions.sh" 2>/dev/null || echo "0")
    if [[ $func_count -gt 0 ]]; then
      details+="Functions: $func_count defined\n  "
    else
      details+="Functions: none found\n  "
      issues=$((issues + 1))
    fi

    # Count aliases defined in aliases.sh
    local alias_count
    alias_count=$(grep -c "^alias " "$HOME/.config/shell/aliases.sh" 2>/dev/null || echo "0")
    if [[ $alias_count -gt 0 ]]; then
      details+="Aliases: $alias_count defined\n  "
    else
      details+="Aliases: none found\n  "
      issues=$((issues + 1))
    fi
  else
    details+="Shell config files: $missing_files missing\n  "
    issues=$((issues + 1))
    add_suggestion "Apply shared shell configuration: make nix-switch"
  fi

  # Check PATH
  local path_items=(git node pnpm)
  local path_ok=true

  for item in "${path_items[@]}"; do
    if ! command -v "$item" &>/dev/null; then
      path_ok=false
      details+="⚠ $item not found in PATH\n  "
    fi
  done

  if $path_ok; then
    details+="Core PATH: Git, Node.js, pnpm found"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Shell Configuration" 0 "$details"
  else
    record_result "Shell Configuration" 2 "$details"
  fi
}

check_developer() {

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
    "$dev_root/work"
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

  # Count repos per category (depth-bounded, prunes node_modules/vendor/.build/Pods)
  local total personal_projects personal_experiments personal_learning work archive
  personal_projects=$(find_git_dirs "$dev_root/personal" | wc -l | xargs)
  personal_experiments=$(find_git_dirs "$dev_root/personal/experiments" | wc -l | xargs)
  personal_learning=$(find_git_dirs "$dev_root/personal/learning" | wc -l | xargs)
  work=$(find_git_dirs "$dev_root/work" | wc -l | xargs)
  archive=$(find_git_dirs "$dev_root/archive" | wc -l | xargs)
  total=$((personal_projects + personal_experiments + personal_learning + work + archive))

  details+="Repositories: $total total\n  "
  details+="  - personal: $personal_projects\n  "
  details+="  - personal/experiments: $personal_experiments\n  "
  details+="  - personal/learning: $personal_learning\n  "
  details+="  - work: $work\n  "
  details+="  - archive: $archive"

  # Detect multiple unique dotfiles clones to prevent configuration ownership conflicts.
  local canonical_paths=""
  local unique_count=0
  local candidate canonical
  for candidate in "$HOME/dotfiles" "$dev_root/personal/dotfiles" "$dev_root/personal/projects/dotfiles"; do
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
    add_suggestion "Keep one clone only to avoid configuration ownership conflicts"
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

  local details=""

  # Node.js is part of the shared Nix JavaScript capability.
  if command -v node &>/dev/null; then
    local node_version
    node_version=$(node --version)
    details+="Node.js: $node_version\n  "
  else
    details+="Node.js: not installed\n  "
    add_suggestion "Apply the shared JavaScript capability: make nix-switch"
  fi

  # uv is opt-in per project; it is not part of the shared machine baseline.
  if command -v uv &>/dev/null; then
    local uv_version
    uv_version=$(uv --version)
    details+="uv: $uv_version"
    if uv python list 2>/dev/null | grep -q "cpython"; then
      local py_version
      py_version=$(uv python list 2>/dev/null | grep "cpython" | head -1 | awk '{print $1}')
      details+="\n  Python: $py_version (via uv)"
    else
      details+="\n  ⚠ Python: no versions installed"
      add_suggestion "Install the required Python version in that project: uv python install"
    fi
  else
    details+="uv: not installed (optional per project)"
  fi

  record_result "Runtime Environments" 0 "$details"
}
