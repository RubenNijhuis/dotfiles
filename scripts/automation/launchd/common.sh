#!/usr/bin/env bash
# Shared launchd-manager configuration and helper functions.

# shellcheck disable=SC2034  # Shared constants consumed by sourced command handlers.
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

agent_log_file() {
  local agent_name="$1"
  case "$agent_name" in
    dotfiles-doctor)
      echo "$LOG_DIR/dotfiles-doctor-launchd.out.log"
      ;;
    *)
      echo "$LOG_DIR/${agent_name}.out.log"
      ;;
  esac
}

render_plist_template() {
  local source="$1"
  local destination="$2"
  local escaped_dotfiles
  local escaped_home
  local escaped_homebrew_prefix

  escaped_dotfiles=$(printf '%s\n' "$DOTFILES" | sed 's/[\/&]/\\&/g')
  escaped_home=$(printf '%s\n' "$HOME" | sed 's/[\/&]/\\&/g')
  escaped_homebrew_prefix=$(printf '%s\n' "${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}" | sed 's/[\/&]/\\&/g')

  # Render placeholder-based templates.
  sed \
    -e "s|__DOTFILES__|$escaped_dotfiles|g" \
    -e "s|__HOME__|$escaped_home|g" \
    -e "s|__HOMEBREW_PREFIX__|$escaped_homebrew_prefix|g" \
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
  cat << EOF2
Usage: $0 [--help] [--no-color] <command> [agent-name]

Commands:
  install <agent>   Install and load a LaunchD agent
  install-all       Install and load all available LaunchD agents
  uninstall <agent> Unload and remove a LaunchD agent
  list              List all available agents
  status            Show status of installed agents
  restart <agent>   Restart a running agent

Available agents:
EOF2
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
