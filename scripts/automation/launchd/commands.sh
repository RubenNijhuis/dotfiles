#!/usr/bin/env bash
# Launchd-manager command handlers.

list_agents() {
  print_header "Available LaunchD Agents"

  local plist_file
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
  local plist_file log_file last_run
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

      log_file="$(agent_log_file "$name")"
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

  if [[ ! -f "$plist_source" ]]; then
    print_error "Agent '$agent_name' not found"
    echo ""
    echo "Available agents:"
    list_agents
    exit 1
  fi

  mkdir -p "$LAUNCHD_DIR" "$LOG_DIR"

  if [[ -f "$plist_dest" ]]; then
    print_warning "Agent already installed, replacing..."
    unload_plist "$plist_dest" || true
  fi

  if ! render_plist_template "$plist_source" "$plist_dest"; then
    printf "  "
    print_error "Failed to write plist to $plist_dest"
    return 1
  fi
  printf "  "
  print_success "Installed plist to ~/Library/LaunchAgents/ (with local paths)"

  if load_plist "$plist_dest"; then
    printf "  "
    print_success "Agent loaded successfully"
  else
    printf "  "
    print_error "Failed to load agent"
    exit 1
  fi

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

  if is_agent_loaded "$agent_name"; then
    unload_plist "$plist_dest" || true
    printf "  "
    print_success "Agent stopped"
  fi

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

run_command() {
  local command="$1"
  local agent="$2"

  case "$command" in
    install)
      if [[ -z "$agent" ]]; then
        print_error "Agent name required"
        printf '\n'
        show_usage
        exit 1
      fi
      install_agent "$agent"
      ;;
    install-all)
      install_all_agents
      ;;
    uninstall)
      if [[ -z "$agent" ]]; then
        print_error "Agent name required"
        printf '\n'
        show_usage
        exit 1
      fi
      uninstall_agent "$agent"
      ;;
    list)
      list_agents
      ;;
    status)
      status_agents
      ;;
    restart)
      if [[ -z "$agent" ]]; then
        print_error "Agent name required"
        printf '\n'
        show_usage
        exit 1
      fi
      restart_agent "$agent"
      ;;
    *)
      print_error "Unknown command '$command'"
      printf '\n'
      show_usage
      exit 1
      ;;
  esac
}
