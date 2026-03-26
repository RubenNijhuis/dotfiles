#!/usr/bin/env bash
# Doctor checks: launchd, homebrew, backup checks.

check_launchd() {
  if $QUICK_MODE; then
    return
  fi

  print_subsection "Checking LaunchD Agents..."
  printf '\n'

  local details=""
  local loaded_agents=0

  # Source agent registry from launchd common module
  LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"
  local managed_agents=()
  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name _desc <<< "$agent_info"
    managed_agents+=("$name")
  done

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
  local log_dir="$HOME/.local/log"
  if [[ ! -d "$log_dir" ]]; then
    details+="\n  ⚠ Log directory missing"
    add_suggestion "Create log directory: mkdir -p ~/.local/log"
  else
    # Check for recent errors in agent log files
    local agents_with_errors=()
    for agent in "${managed_agents[@]}"; do
      local log_file="$log_dir/${agent}.out.log"
      [[ "$agent" == "dotfiles-doctor" ]] && log_file="$log_dir/dotfiles-doctor-launchd.out.log"
      if [[ -f "$log_file" ]]; then
        local recent_errors
        recent_errors=$(tail -n 50 "$log_file" 2>/dev/null | grep -c "ERROR" || true)
        if [[ $recent_errors -gt 0 ]]; then
          agents_with_errors+=("$agent ($recent_errors errors)")
        fi
      fi
    done

    if [[ ${#agents_with_errors[@]} -gt 0 ]]; then
      details+="\n  ⚠ Agents with recent log errors:"
      for entry in "${agents_with_errors[@]}"; do
        details+="\n    - $entry"
      done
      add_suggestion "Check agent logs: ls ~/.local/log/"
    fi
  fi

  record_result "LaunchD Agents" 0 "$details"
}

check_homebrew() {
  if $QUICK_MODE; then
    return
  fi

  print_subsection "Checking Homebrew..."
  printf '\n'

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

  record_result "Homebrew" 0 "$details"
}

check_tmux() {
  if $QUICK_MODE; then
    return
  fi

  print_subsection "Checking tmux..."
  printf '\n'

  local issues=0
  local details=""

  if ! command -v tmux &>/dev/null; then
    record_result "tmux" 2 "tmux not installed"
    add_suggestion "Install tmux: brew install tmux"
    return
  fi

  local tmux_version
  tmux_version=$(tmux -V 2>/dev/null)
  details+="$tmux_version\n  "

  # Check config exists
  if [[ -f "$HOME/.config/tmux/tmux.conf" ]]; then
    details+="Config: ~/.config/tmux/tmux.conf\n  "
  else
    details+="Config: missing\n  "
    issues=$((issues + 1))
    add_suggestion "Re-stow tmux config: cd $DOTFILES && make stow"
  fi

  # Check tpm installed
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    local plugin_count
    plugin_count=$(find "$HOME/.tmux/plugins" -maxdepth 1 -mindepth 1 -type d | wc -l | xargs)
    details+="Plugins: $plugin_count installed (tpm)"
  else
    details+="Plugins: tpm not installed"
    issues=$((issues + 1))
    add_suggestion "Install tpm: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "tmux" 0 "$details"
  else
    record_result "tmux" 1 "$details"
  fi
}

check_shell_perf() {
  if $QUICK_MODE; then
    return
  fi

  print_subsection "Checking Shell Startup Time..."
  printf '\n'

  if ! command -v zsh &>/dev/null; then
    record_result "Shell Performance" 1 "zsh not found"
    return
  fi

  # Measure zsh startup time (average of 3 runs for stability)
  # Use python3 for portable millisecond timestamps (macOS date lacks %N)
  local total_ms=0
  local runs=3
  for _ in $(seq 1 $runs); do
    local start_ms end_ms elapsed_ms
    start_ms=$(python3 -c 'import time; print(int(time.time()*1000))')
    zsh -i -c exit 2>/dev/null
    end_ms=$(python3 -c 'import time; print(int(time.time()*1000))')
    elapsed_ms=$((end_ms - start_ms))
    total_ms=$((total_ms + elapsed_ms))
  done
  local avg_ms=$((total_ms / runs))

  local details="Average startup: ${avg_ms}ms (${runs} runs)"

  if [[ $avg_ms -gt 300 ]]; then
    record_result "Shell Performance" 2 "$details — exceeds 300ms threshold"
    add_suggestion "Profile shell startup: zsh -xvlic exit 2>&1 | head -100"
  elif [[ $avg_ms -gt 200 ]]; then
    record_result "Shell Performance" 1 "$details — exceeds 200ms threshold"
    add_suggestion "Profile shell startup: zsh -xvlic exit 2>&1 | head -100"
  else
    record_result "Shell Performance" 0 "$details"
  fi
}

check_backup_system() {
  if $QUICK_MODE; then
    return
  fi

  print_subsection "Checking Backup System..."
  printf '\n'

  local issues=0
  local details=""

  local BACKUP_DIR LATEST_BACKUP BACKUP_AGE_DAYS
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
    add_suggestion "Setup automation: make automation-setup"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Backup System" 0 "$details"
  else
    record_result "Backup System" 1 "$details"
  fi
}

