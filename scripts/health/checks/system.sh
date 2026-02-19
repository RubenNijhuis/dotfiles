#!/usr/bin/env bash
# Doctor checks: launchd, homebrew, backup checks.

check_launchd() {
  if $QUICK_MODE; then
    return
  fi

  printf '%sChecking LaunchD Agents...%s\n' "${BLUE}" "${NC}"
  echo ""

  local details=""
  local loaded_agents=0
  local managed_agents=(dotfiles-backup dotfiles-doctor obsidian-sync repo-update)

  for agent in "${managed_agents[@]}"; do
    if launchctl print "gui/$(id -u)/com.user.$agent" >/dev/null 2>&1; then
      loaded_agents=$((loaded_agents + 1))
    fi
  done

  if [[ $loaded_agents -gt 0 ]]; then
    details+="Managed agents loaded: $loaded_agents/${#managed_agents[@]}"
  else
    details+="No managed agents loaded"
  fi

  # Check log directory exists
  if [[ ! -d "$HOME/.local/log" ]]; then
    details+="\n  ⚠ Log directory missing"
    add_suggestion "Create log directory: mkdir -p ~/.local/log"
  fi

  record_result "LaunchD Agents" 0 "$details"
}

check_homebrew() {
  if $QUICK_MODE; then
    return
  fi

  printf '%sChecking Homebrew...%s\n' "${BLUE}" "${NC}"
  echo ""

  local details=""

  if command -v brew &>/dev/null; then
    local brew_version=$(brew --version | head -1)
    details+="Homebrew: $brew_version\n  "

    # Check for outdated packages (warning only)
    local outdated=$(brew outdated 2>/dev/null | wc -l | xargs)
    if [[ $outdated -gt 0 ]]; then
      details+="⚠ $outdated outdated packages"
      add_suggestion "Update packages: brew upgrade"
    else
      details+="All packages up to date"
    fi
  else
    details+="Homebrew: not installed"
    add_suggestion "Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  fi

  # Check profile
  if [[ -f "$HOME/.config/dotfiles-profile" ]]; then
    local profile=$(cat "$HOME/.config/dotfiles-profile")
    details+="\n  Profile: $profile"
  fi

  record_result "Homebrew" 0 "$details"
}

check_vscode_config() {
  if $QUICK_MODE; then
    return
  fi

  printf '%sChecking VS Code Configuration...%s\n\n' "${BLUE}" "${NC}"

  local issues=0
  local details=""

  if ! command -v code &>/dev/null; then
    record_result "VS Code" 1 "VS Code not installed"
    add_suggestion "Install VS Code: brew install --cask visual-studio-code"
    return
  fi

  details+="VS Code: installed\n  "

  INSTALLED_EXTENSIONS=$(code --list-extensions 2>/dev/null)
  REQUIRED_EXTENSIONS=(
    "editorconfig.editorconfig"
    "biomejs.biome"
    "foxundermoon.shell-format"
  )

  missing_extensions=()
  for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if ! echo "$INSTALLED_EXTENSIONS" | grep -q "$ext"; then
      missing_extensions+=("$ext")
    fi
  done

  if [[ ${#missing_extensions[@]} -gt 0 ]]; then
    details+="Extensions: missing ${#missing_extensions[@]}\n  "
    for ext in "${missing_extensions[@]}"; do
      details+="  • $ext\n  "
    done
    issues=$((issues + 1))
    add_suggestion "Install extensions: make vscode-setup"
  else
    details+="Extensions: all required installed"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "VS Code Configuration" 0 "$details"
  else
    record_result "VS Code Configuration" 1 "$details"
  fi
}

check_backup_system() {
  if $QUICK_MODE; then
    return
  fi

  printf '%sChecking Backup System...%s\n\n' "${BLUE}" "${NC}"

  local issues=0
  local details=""

  BACKUP_DIR="$HOME/.dotfiles-backup"

  if [[ ! -d "$BACKUP_DIR" ]]; then
    record_result "Backup System" 1 "No backups at $BACKUP_DIR"
    add_suggestion "Create backup: make backup"
    return
  fi

  LATEST_BACKUP=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "202*" | sort -r | head -n1)

  if [[ -n "$LATEST_BACKUP" ]]; then
    BACKUP_AGE_DAYS=$(( ($(date +%s) - $(stat -f %m "$LATEST_BACKUP")) / 86400 ))

    if [[ $BACKUP_AGE_DAYS -gt 7 ]]; then
      details+="Recent backup: $BACKUP_AGE_DAYS days old (too old)\n  "
      issues=$((issues + 1))
      add_suggestion "Create backup: make backup"
    else
      details+="Recent backup: $BACKUP_AGE_DAYS days ago\n  "
    fi

    # Count total backups
    local backup_count=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "202*" | wc -l | xargs)
    details+="Total backups: $backup_count\n  "
  else
    details+="No backups found\n  "
    issues=$((issues + 1))
    add_suggestion "Create backup: make backup"
  fi

  # Check LaunchD automation
  if launchctl print "gui/$(id -u)/com.user.dotfiles-backup" >/dev/null 2>&1; then
    details+="Automation: LaunchD agent running"
  else
    details+="Automation: not configured"
    add_suggestion "Setup automation: make backup-setup"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Backup System" 0 "$details"
  else
    record_result "Backup System" 1 "$details"
  fi
}

