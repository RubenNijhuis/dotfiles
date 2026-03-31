#!/usr/bin/env bash
# Unified LaunchD agent management tool
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034  # DOTFILES used by sourced scripts and render_plist_template.
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/env.sh"
dotfiles_load_env "$DOTFILES"

# --- Configuration -----------------------------------------------------------

LAUNCHD_DIR="$HOME/Library/LaunchAgents"
TEMPLATE_DIR="$DOTFILES/launchd"
LOG_DIR="$HOME/.local/log"

# shellcheck disable=SC2034  # AGENTS is consumed by ops-status.sh and weekly-digest.sh.
AGENTS=(
  "dotfiles-backup:Automated daily backups"
  "dotfiles-doctor:Daily health monitoring"
  "obsidian-sync:Obsidian vault synchronization"
  "repo-update:Repository updates"
  "log-cleanup:Weekly log rotation"
  "brew-audit:Weekly Brewfile drift detection"
  "weekly-digest:Weekly automation health digest"
  "lmstudio-server:LM Studio local server"
)

# --- Helpers -----------------------------------------------------------------

agent_log_file() {
  local name="$1"
  case "$name" in
    dotfiles-doctor) echo "$LOG_DIR/dotfiles-doctor-launchd.out.log" ;;
    *) echo "$LOG_DIR/${name}.out.log" ;;
  esac
}

agent_label() { printf 'com.user.%s' "$1"; }
launchd_domain() { printf 'gui/%s' "$(id -u)"; }

is_agent_loaded() {
  launchctl print "$(launchd_domain)/$(agent_label "$1")" >/dev/null 2>&1
}

render_plist_template() {
  local source="$1" dest="$2"
  local e_dotfiles e_home e_prefix e_obsidian
  e_dotfiles=$(printf '%s\n' "$DOTFILES" | sed 's/[|&]/\\&/g')
  e_home=$(printf '%s\n' "$HOME" | sed 's/[|&]/\\&/g')
  e_prefix=$(printf '%s\n' "${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}" | sed 's/[|&]/\\&/g')
  e_obsidian=$(printf '%s\n' "${DOTFILES_OBSIDIAN_REPO_PATH:-$HOME/Developer/personal/projects/obsidian-store}" | sed 's/[|&]/\\&/g')
  sed -e "s|__DOTFILES__|${e_dotfiles}|g" -e "s|__HOME__|${e_home}|g" \
      -e "s|__HOMEBREW_PREFIX__|${e_prefix}|g" -e "s|__OBSIDIAN_REPO_PATH__|${e_obsidian}|g" \
      "$source" > "$dest"
}

load_plist() {
  launchctl bootstrap "$(launchd_domain)" "$1" 2>/dev/null || launchctl load "$1" 2>/dev/null
}

unload_plist() {
  launchctl bootout "$(launchd_domain)" "$1" 2>/dev/null || launchctl unload "$1" 2>/dev/null
}

# --- Commands ----------------------------------------------------------------

cmd_list() {
  print_header "Available LaunchD Agents"
  for info in "${AGENTS[@]}"; do
    IFS=':' read -r name desc <<< "$info"
    printf "  "
    if [[ -f "$TEMPLATE_DIR/com.user.$name.plist" ]]; then print_success "$name — $desc"
    else print_warning "$name — $desc (template missing)"; fi
  done
}

cmd_status() {
  print_header "LaunchD Agent Status"
  local loaded=0
  for info in "${AGENTS[@]}"; do
    IFS=':' read -r name _ <<< "$info"
    printf "  "
    if is_agent_loaded "$name"; then
      loaded=$((loaded + 1))
      print_success "$name (loaded)"
      local lf last_mod
      lf="$(agent_log_file "$name")"
      if [[ -f "$lf" ]]; then
        last_mod=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$lf" 2>/dev/null || echo "unknown")
        printf "    "; print_dim "Last: $last_mod"
      fi
    else
      print_dim "$name (not loaded)"
    fi
  done
  if [[ $loaded -eq 0 ]]; then print_warning "No managed agents loaded"; fi
}

cmd_install() {
  local name="$1"
  local src="$TEMPLATE_DIR/com.user.$name.plist"
  local dest="$LAUNCHD_DIR/com.user.$name.plist"
  [[ -f "$src" ]] || { print_error "Agent '$name' not found"; exit 1; }
  mkdir -p "$LAUNCHD_DIR" "$LOG_DIR"
  [[ -f "$dest" ]] && { unload_plist "$dest" || true; }
  render_plist_template "$src" "$dest"
  load_plist "$dest" || { print_error "Failed to load $name"; exit 1; }
  print_success "Installed $name"
}

cmd_uninstall() {
  local name="$1"
  local dest="$LAUNCHD_DIR/com.user.$name.plist"
  [[ -f "$dest" ]] || { print_info "$name not installed"; return 0; }
  is_agent_loaded "$name" && { unload_plist "$dest" || true; }
  rm "$dest"
  print_success "Uninstalled $name"
}

cmd_restart() {
  local name="$1"
  local dest="$LAUNCHD_DIR/com.user.$name.plist"
  [[ -f "$dest" ]] || { print_error "$name not installed"; exit 1; }
  is_agent_loaded "$name" && { unload_plist "$dest" || true; }
  load_plist "$dest" || { print_error "Failed to start $name"; exit 1; }
  print_success "Restarted $name"
}

cmd_install_all() {
  print_header "Installing All LaunchD Agents"
  local ok=0 fail=0
  for info in "${AGENTS[@]}"; do
    IFS=':' read -r name _ <<< "$info"
    if cmd_install "$name"; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
  done
  print_info "Installed: $ok"
  if [[ $fail -gt 0 ]]; then print_warning "Failed: $fail"; return 1; fi
}

cmd_uninstall_all() {
  print_header "Uninstalling All LaunchD Agents"
  for info in "${AGENTS[@]}"; do
    IFS=':' read -r name _ <<< "$info"
    cmd_uninstall "$name"
  done
}

# --- Main --------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] <command> [agent-name]

Commands:
  install <agent>   Install and load a LaunchD agent
  install-all       Install and load all agents
  uninstall <agent> Unload and remove a LaunchD agent
  uninstall-all     Unload and remove all agents
  list              List available agents
  status            Show status of installed agents
  restart <agent>   Restart a running agent
EOF
}

# Allow sourcing for AGENTS array and helper functions without running main.
# Usage: LAUNCHD_MANAGER_SOURCE_ONLY=1 source launchd-manager.sh
# shellcheck disable=SC2317
if [[ "${LAUNCHD_MANAGER_SOURCE_ONLY:-}" == "1" ]]; then return 0 2>/dev/null || exit 0; fi

show_help_if_requested usage "$@"
# Filter flags, collect positional args
args=()
for arg in "$@"; do
  case "$arg" in --no-color|--help|-h) ;; *) args+=("$arg") ;; esac
done

[[ ${#args[@]} -eq 0 ]] && { usage; exit 1; }
command="${args[0]}"
agent="${args[1]:-}"

case "$command" in
  install)     [[ -z "$agent" ]] && { print_error "Agent name required"; exit 1; }; cmd_install "$agent" ;;
  install-all) cmd_install_all ;;
  uninstall)   [[ -z "$agent" ]] && { print_error "Agent name required"; exit 1; }; cmd_uninstall "$agent" ;;
  uninstall-all) cmd_uninstall_all ;;
  list)        cmd_list ;;
  status)      cmd_status ;;
  restart)     [[ -z "$agent" ]] && { print_error "Agent name required"; exit 1; }; cmd_restart "$agent" ;;
  *)           print_error "Unknown command '$command'"; usage; exit 1 ;;
esac
