#!/usr/bin/env bash
# Setup LaunchD automation for managed dotfiles tasks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

LAUNCHD_MANAGER="$DOTFILES/scripts/launchd-manager.sh"
TARGET=""

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] <backup|doctor|repo-update|ai-startup>

Examples:
  $0 backup
  $0 doctor
  $0 repo-update
  $0 ai-startup
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      backup|doctor|repo-update|ai-startup)
        TARGET="$1"
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "$TARGET" ]]; then
    usage
    exit 1
  fi
}

setup_backup() {
  print_header "Setting Up Backup Automation"

  local log_dir="$HOME/.local/log"
  if [[ ! -d "$log_dir" ]]; then
    mkdir -p "$log_dir"
    printf "  "
    print_success "Created log directory: $log_dir"
  fi

  printf '\n'
  print_section "Installing LaunchD agent..."
  if "$LAUNCHD_MANAGER" install dotfiles-backup; then
    printf "  "
    print_success "Backup automation installed via launchd-manager"
  else
    printf "  "
    print_error "Failed to install backup automation"
    exit 1
  fi

  printf '\n'
  print_section "Verification:"
  if launchctl print "gui/$(id -u)/com.user.dotfiles-backup" >/dev/null 2>&1; then
    printf "  "
    print_success "Agent is running"
  else
    printf "  "
    print_error "Agent failed to load"
    exit 1
  fi

  printf '\n'
  print_info "Automated backups will run daily at 2:00 AM"
  print_info "Logs: $log_dir/dotfiles-backup.out.log"
  print_info "Check status: make backup-status"
  printf '\n'
}

setup_doctor() {
  print_header "Setting Up Health Monitoring Automation"

  local log_dir="$HOME/.local/log"
  if [[ ! -d "$log_dir" ]]; then
    mkdir -p "$log_dir"
    printf "  "
    print_success "Created log directory: $log_dir"
  fi

  printf '\n'
  print_section "Installing LaunchD agent..."
  if "$LAUNCHD_MANAGER" install dotfiles-doctor; then
    printf "  "
    print_success "Health monitoring installed via launchd-manager"
  else
    printf "  "
    print_error "Failed to install health monitoring"
    exit 1
  fi

  printf '\n'
  print_section "Testing notification system..."
  if osascript -e 'display notification "Dotfiles health monitoring is now active" with title "Setup Complete"' 2>/dev/null; then
    printf "  "
    print_success "Notification test passed"
  else
    printf "  "
    print_warning "Notification test failed - check System Preferences > Notifications"
  fi

  printf '\n'
  print_section "Verification:"
  if launchctl print "gui/$(id -u)/com.user.dotfiles-doctor" >/dev/null 2>&1; then
    printf "  "
    print_success "Agent is running"
  else
    printf "  "
    print_error "Agent failed to load"
    exit 1
  fi

  printf '\n'
  print_info "Health checks will run daily at 9:00 AM"
  print_info "Notifications sent on failures only"
  print_info "Logs: $log_dir/dotfiles-doctor.out.log"
  print_info "Check status: make doctor-status"
  printf '\n'
}

setup_repo_update() {
  print_header "Setting Up Repository Update Automation"

  local log_dir="$HOME/.local/log"
  mkdir -p "$log_dir"

  if ! bash "$DOTFILES/scripts/check-keychain.sh" --no-color; then
    print_error "Keychain requirements not satisfied; aborting repo-update automation setup"
    exit 1
  fi

  printf '\n'
  print_section "Installing LaunchD agent..."
  if "$LAUNCHD_MANAGER" install repo-update; then
    printf "  "
    print_success "Repository update automation installed"
  else
    printf "  "
    print_error "Failed to install repository update automation"
    exit 1
  fi

  printf '\n'
  print_section "Verification:"
  if launchctl print "gui/$(id -u)/com.user.repo-update" >/dev/null 2>&1; then
    printf "  "
    print_success "Agent is running"
  else
    printf "  "
    print_error "Agent failed to load"
    exit 1
  fi

  printf '\n'
  print_info "Repository updates will run daily at 9:30 AM"
  print_info "Summary log: $log_dir/repo-update-summary.log"
  print_info "Check status: make repo-update-status"
  printf '\n'
}

setup_ai_startup() {
  print_header "Setting Up AI Startup Selector Automation"

  local log_dir="$HOME/.local/log"
  mkdir -p "$log_dir"

  printf '\n'
  print_section "Installing LaunchD agent..."
  if "$LAUNCHD_MANAGER" install ai-startup-selector; then
    printf "  "
    print_success "AI startup selector installed"
  else
    printf "  "
    print_error "Failed to install AI startup selector"
    exit 1
  fi

  printf '\n'
  print_section "Verification:"
  if launchctl print "gui/$(id -u)/com.user.ai-startup-selector" >/dev/null 2>&1; then
    printf "  "
    print_success "Agent is running"
  else
    printf "  "
    print_error "Agent failed to load"
    exit 1
  fi

  printf '\n'
  print_info "Selector runs at login and prompts for OpenClaw/LM Studio startup."
  print_info "Logs: $log_dir/ai-startup-selector.log"
  print_info "Check status: make ai-startup-status"
  printf '\n'
}

main() {
  parse_args "$@"

  if [[ ! -x "$LAUNCHD_MANAGER" ]]; then
    print_error "launchd-manager script not found or not executable: $LAUNCHD_MANAGER"
    exit 1
  fi

  case "$TARGET" in
    backup) setup_backup ;;
    doctor) setup_doctor ;;
    repo-update) setup_repo_update ;;
    ai-startup) setup_ai_startup ;;
  esac
}

main "$@"
