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

check_stow() {
  # Compatibility name retained for the public doctor section. This checks
  # chezmoi source-state sync; Stow is no longer part of the setup.
  if ! command -v chezmoi >/dev/null 2>&1; then
    record_result "chezmoi" 1 "chezmoi not installed"
    add_suggestion "Apply the Nix configuration: make nix-switch"
    return
  fi

  # Soft warn when chezmoi isn't pointed at this repo's source state — common
  # in CI/test sandboxes where ~/.config/chezmoi/chezmoi.toml isn't seeded.
  local source_dir
  source_dir="$(chezmoi source-path 2>/dev/null || echo "")"
  if [[ -z "$source_dir" || ! -d "$source_dir" ]]; then
    record_result "chezmoi" 1 "source dir not configured (no ~/.config/chezmoi/chezmoi.toml?)"
    add_suggestion "echo 'sourceDir = \"$DOTFILES/chezmoi\"' > ~/.config/chezmoi/chezmoi.toml"
    return
  fi

  # ChezMoi retains stale status rows for paths that Nix has taken over. Count
  # only rows whose target is still in its managed-file list; applying every
  # status row here could overwrite a completed Nix handoff.
  local files dirs pending managed_paths status line path
  files=$(chezmoi managed --include=files 2>/dev/null | wc -l | xargs)
  dirs=$(chezmoi managed --include=dirs 2>/dev/null | wc -l | xargs)
  managed_paths=$(chezmoi managed --include=files 2>/dev/null)
  status=$(chezmoi status 2>/dev/null || true)
  pending=0
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    path="${line:3}"
    if printf '%s\n' "$managed_paths" | grep -Fxq "$path"; then
      pending=$((pending + 1))
    fi
  done <<< "$status"

  if [[ "$pending" -eq 0 ]]; then
    record_result "chezmoi" 0 "${files} files / ${dirs} dirs remain; Nix handoff rows ignored"
  else
    record_result "chezmoi" 1 "${files} files / ${dirs} dirs managed; ${pending} entries differ from source"
    add_suggestion "Review: chezmoi diff (do not apply blindly after a Nix handoff)"
  fi
}

check_ssh() {

  local issues=0
  local details=""

  # Check personal key
  if [[ -f "$HOME/.ssh/id_ed25519_personal" ]]; then
    local perms
    perms=$(stat -f "%OLp" "$HOME/.ssh/id_ed25519_personal" 2>/dev/null || echo "")
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
      add_suggestion "Re-apply SSH config: chezmoi apply"
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

  local gpg_pref
  gpg_pref="$(get_preference "PREF_SETUP_GPG")"
  if [[ "$gpg_pref" == "no" ]]; then
    record_result "GPG Configuration" 0 "${DIM}GPG: skipped (preference)${NC}"
    return
  fi

  # Signing is useful, but it is an opt-in identity decision: creating a key
  # changes external developer identity and must never be presented as a broken
  # machine when no key has been chosen yet.
  if ! gpg --list-secret-keys 2>/dev/null | grep -q '^sec'; then
    record_result "GPG Configuration" 1 "Not configured (optional; create a key only when you choose to sign commits)"
    add_suggestion "Optional: create a GPG signing identity with make gpg-setup"
    return
  fi

  local issues=0
  local details=""

  # Check if GPG key exists
  if gpg --list-secret-keys &>/dev/null; then
    local key_id
    key_id=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)
    details+="Secret key: $key_id\n  "
  fi

  # Check Git signing config
  if git config --global user.signingkey &>/dev/null; then
    details+="Git signing: enabled\n  "
  else
    details+="Git signing: not configured\n  "
    issues=$((issues + 1))
    add_suggestion "Configure GPG signing: make gpg-setup"
  fi

  # Validate pinentry-mac path matches actual Homebrew prefix
  if [[ -f "$HOME/.gnupg/gpg-agent.conf" ]]; then
    local pinentry_path
    pinentry_path=$(grep "^pinentry-program" "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null | awk '{print $2}')
    if [[ -n "$pinentry_path" ]] && [[ ! -f "$pinentry_path" ]]; then
      details+="⚠ pinentry-mac not found at $pinentry_path\n  "
      add_suggestion "Fix pinentry path in ~/.gnupg/gpg-agent.conf (check brew --prefix)"
    fi
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

  local issues=0
  local details=""

  # Home Manager writes the global config at XDG_CONFIG_HOME/git/config rather
  # than ~/.gitconfig. Ask Git for its resolved configuration so either valid
  # layout is accepted.
  if git config --global --get user.email >/dev/null 2>&1; then
    if git config --global --get-regexp '^includeIf\..*\.path$' >/dev/null 2>&1; then
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

  # Detect multiple unique dotfiles clones to prevent stow ownership conflicts.
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
