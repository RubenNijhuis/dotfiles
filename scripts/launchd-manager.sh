#!/usr/bin/env bash
# Unified LaunchD agent management tool
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

LAUNCHD_DIR="$HOME/Library/LaunchAgents"
TEMPLATE_DIR="$DOTFILES/templates/launchd"
LOG_DIR="$HOME/.local/log"

# Available agents
AGENTS=(
  "ai-startup-selector:Prompt at login to start OpenClaw/LM Studio"
  "dotfiles-backup:Automated daily backups"
  "dotfiles-doctor:Daily health monitoring"
  "obsidian-sync:Obsidian vault synchronization"
  "repo-update:Repository updates"
)

render_plist_template() {
  local source="$1"
  local destination="$2"
  local escaped_dotfiles
  local escaped_home

  escaped_dotfiles=$(printf '%s\n' "$DOTFILES" | sed 's/[\/&]/\\&/g')
  escaped_home=$(printf '%s\n' "$HOME" | sed 's/[\/&]/\\&/g')

  # Support both placeholder templates and older hardcoded paths.
  sed \
    -e "s|__DOTFILES__|$escaped_dotfiles|g" \
    -e "s|__HOME__|$escaped_home|g" \
    -e "s|/Users/rubennijhuis/dotfiles|$escaped_dotfiles|g" \
    -e "s|/Users/rubennijhuis|$escaped_home|g" \
    "$source" > "$destination"
}

launchd_domain() {
  printf 'gui/%s' "$(id -u)"
}

agent_label() {
  local agent_name="$1"
  printf 'com.user.%s' "$agent_name"
}

is_agent_loaded() {
  local agent_name="$1"
  local label
  label="$(agent_label "$agent_name")"
  launchctl print "$(launchd_domain)/$label" >/dev/null 2>&1
}

load_plist() {
  local plist_path="$1"
  local domain
  domain="$(launchd_domain)"

  if launchctl bootstrap "$domain" "$plist_path" 2>/dev/null; then
    return 0
  fi

  # Fallback for older launchctl behavior.
  launchctl load "$plist_path" 2>/dev/null
}

unload_plist() {
  local plist_path="$1"
  local domain
  domain="$(launchd_domain)"

  if launchctl bootout "$domain" "$plist_path" 2>/dev/null; then
    return 0
  fi

  # Fallback for older launchctl behavior.
  launchctl unload "$plist_path" 2>/dev/null
}

show_usage() {
  cat << EOF
Usage: $0 [--help] [--no-color] <command> [agent-name]

Commands:
  install <agent>   Install and load a LaunchD agent
  install-all       Install and load all available LaunchD agents
  uninstall <agent> Unload and remove a LaunchD agent
  list              List all available agents
  status            Show status of installed agents
  restart <agent>   Restart a running agent

Available agents:
EOF
  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name desc <<< "$agent_info"
    printf "  %-20s %s\n" "$name" "$desc"
  done
  echo ""
  echo "Examples:"
  echo "  $0 install dotfiles-backup"
  echo "  $0 install-all"
  echo "  $0 status"
  echo "  $0 restart dotfiles-doctor"
}

parse_args() {
  show_help_if_requested show_usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
  fi

  COMMAND="$1"
  AGENT="${2:-}"
}

list_agents() {
  print_header "Available LaunchD Agents"

  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name desc <<< "$agent_info"
    plist_file="$TEMPLATE_DIR/com.user.$name.plist"

    printf "  "
    if [[ -f "$plist_file" ]]; then
      print_success "$name - $desc"
    else
      print_warning "$name - $desc (template missing)"
    fi
  done
  printf '\n'
}

status_agents() {
  print_header "LaunchD Agent Status"

  local loaded_count=0
  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name _desc <<< "$agent_info"
    plist_file="$LAUNCHD_DIR/$(agent_label "$name").plist"

    printf "  "
    if is_agent_loaded "$name"; then
      loaded_count=$((loaded_count + 1))
      if [[ -f "$plist_file" ]]; then
        print_success "$name (loaded)"
      else
        print_warning "$name (loaded but plist missing)"
      fi

      # Show last run if log exists
      log_file="$LOG_DIR/${name}.out.log"
      if [[ -f "$log_file" ]]; then
        last_run=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$log_file" 2>/dev/null || echo "never")
        printf "    "
        print_dim "Last activity: $last_run"
      fi
    else
      print_dim "$name (not loaded)"
    fi
  done

  if [[ $loaded_count -eq 0 ]]; then
    print_warning "No managed agents loaded"
  fi

  printf '\n'
}

install_agent() {
  local agent_name="$1"
  local plist_name="com.user.$agent_name"
  local plist_source="$TEMPLATE_DIR/$plist_name.plist"
  local plist_dest="$LAUNCHD_DIR/$plist_name.plist"

  print_header "Installing LaunchD Agent: $agent_name"

  # Validate agent exists
  if [[ ! -f "$plist_source" ]]; then
    print_error "Agent '$agent_name' not found"
    echo ""
    echo "Available agents:"
    list_agents
    exit 1
  fi

  # Create directories
  mkdir -p "$LAUNCHD_DIR" "$LOG_DIR"

  # Check if already installed
  if [[ -f "$plist_dest" ]]; then
    print_warning "Agent already installed, replacing..."
    unload_plist "$plist_dest" || true
  fi

  # Render plist with local paths
  if ! render_plist_template "$plist_source" "$plist_dest"; then
    printf "  "
    print_error "Failed to write plist to $plist_dest"
    return 1
  fi
  printf "  "
  print_success "Installed plist to ~/Library/LaunchAgents/ (with local paths)"

  # Load agent
  if load_plist "$plist_dest"; then
    printf "  "
    print_success "Agent loaded successfully"
  else
    printf "  "
    print_error "Failed to load agent"
    exit 1
  fi

  # Verify
  printf '\n'
  print_section "Verification:"
  if is_agent_loaded "$agent_name"; then
    printf "  "
    print_success "Agent is running"
  else
    printf "  "
    print_error "Agent not found in launchd domain"
    exit 1
  fi

  printf '\n'
  print_info "Check logs: tail -f $LOG_DIR/${agent_name}*.log"
}

uninstall_agent() {
  local agent_name="$1"
  local plist_name="com.user.$agent_name"
  local plist_dest="$LAUNCHD_DIR/$plist_name.plist"

  print_header "Uninstalling LaunchD Agent: $agent_name"

  if [[ ! -f "$plist_dest" ]]; then
    print_warning "Agent not installed"
    exit 0
  fi

  # Unload
  if is_agent_loaded "$agent_name"; then
    if unload_plist "$plist_dest"; then
      printf "  "
      print_success "Agent unloaded"
    else
      printf "  "
      print_warning "Failed to unload (may not be running)"
    fi
  else
    printf "  "
    print_info "Agent not running"
  fi

  # Remove plist
  rm "$plist_dest"
  printf "  "
  print_success "Removed plist"

  printf '\n'
  print_success "Agent uninstalled"
}

restart_agent() {
  local agent_name="$1"
  local plist_name="com.user.$agent_name"
  local plist_dest="$LAUNCHD_DIR/$plist_name.plist"

  print_header "Restarting LaunchD Agent: $agent_name"

  if [[ ! -f "$plist_dest" ]]; then
    print_error "Agent not installed"
    exit 1
  fi

  # Unload
  if is_agent_loaded "$agent_name"; then
    unload_plist "$plist_dest" || true
    printf "  "
    print_success "Agent stopped"
  fi

  # Load
  if load_plist "$plist_dest"; then
    printf "  "
    print_success "Agent started"
  else
    printf "  "
    print_error "Failed to start agent"
    exit 1
  fi

  printf '\n'
}

install_all_agents() {
  print_header "Installing All LaunchD Agents"
  local installed_count=0
  local failed_count=0

  for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r name _desc <<< "$agent_info"
    if install_agent "$name"; then
      installed_count=$((installed_count + 1))
    else
      failed_count=$((failed_count + 1))
    fi
    printf '\n'
  done

  print_section "Summary:"
  print_info "Installed: $installed_count"
  if [[ $failed_count -gt 0 ]]; then
    print_warning "Failed: $failed_count"
    return 1
  fi
  print_success "All agents installed"
}

# Main
COMMAND=""
AGENT=""
parse_args "$@"

case "$COMMAND" in
  install)
    if [[ -z "$AGENT" ]]; then
      print_error "Agent name required"
      printf '\n'
      show_usage
      exit 1
    fi
    install_agent "$AGENT"
    ;;
  install-all)
    install_all_agents
    ;;
  uninstall)
    if [[ -z "$AGENT" ]]; then
      print_error "Agent name required"
      printf '\n'
      show_usage
      exit 1
    fi
    uninstall_agent "$AGENT"
    ;;
  list)
    list_agents
    ;;
  status)
    status_agents
    ;;
  restart)
    if [[ -z "$AGENT" ]]; then
      print_error "Agent name required"
      printf '\n'
      show_usage
      exit 1
    fi
    restart_agent "$AGENT"
    ;;
  *)
    print_error "Unknown command '$COMMAND'"
    printf '\n'
    show_usage
    exit 1
    ;;
esac
