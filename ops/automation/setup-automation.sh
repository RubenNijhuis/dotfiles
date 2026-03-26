#!/usr/bin/env bash
# Setup LaunchD automation for managed dotfiles tasks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/env.sh"
dotfiles_load_env "$DOTFILES"

LAUNCHD_MANAGER="$DOTFILES/ops/automation/launchd-manager.sh"
TARGET=""

# Agent metadata: name|schedule_desc|log_file|pre_check
# pre_check values: "" (none), "test-notifications", "check-keychain",
#                   "check-vault", "check-lmstudio"
AGENT_META=(
  "dotfiles-backup|daily at 2:00 AM|dotfiles-backup.out.log|"
  "dotfiles-doctor|daily at 9:00 AM|dotfiles-doctor.out.log|test-notifications"
  "repo-update|daily at 9:30 AM|repo-update-summary.log|check-keychain"
  "obsidian-sync|daily at 8:00 PM|obsidian-sync.log|check-vault"
  "lmstudio-server|daily at 7:00 AM|lmstudio-server.log|check-lmstudio"
  "log-cleanup|weekly on Sundays at 3:00 AM|log-cleanup.out.log|"
  "brew-audit|weekly on Mondays at 10:00 AM|brew-audit.out.log|"
  "weekly-digest|weekly on Sundays at 10:00 AM|weekly-digest.out.log|"
)

# Agents that are always installed by setup-all
CORE_AGENTS=(dotfiles-backup dotfiles-doctor repo-update log-cleanup brew-audit weekly-digest)

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] <target>

Targets:
  backup         Setup backup automation only
  doctor         Setup health monitoring only
  repo-update    Setup repository update automation only
  obsidian-sync  Setup Obsidian vault sync only
  lmstudio       Setup LM Studio server only
  log-cleanup    Setup log rotation only
  brew-audit     Setup Brewfile drift detection only
  weekly-digest  Setup weekly automation digest only
  setup-all      Setup all applicable automations (auto-detects optional agents)

Examples:
  $0 backup
  $0 setup-all
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      backup|doctor|repo-update|obsidian-sync|lmstudio|log-cleanup|brew-audit|weekly-digest|setup-all)
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

# Map target names to agent names (most are identical)
target_to_agent() {
  local target="$1"
  case "$target" in
    lmstudio) echo "lmstudio-server" ;;
    doctor) echo "dotfiles-doctor" ;;
    backup) echo "dotfiles-backup" ;;
    *) echo "$target" ;;
  esac
}

# Look up metadata for an agent. Sets: AGENT_SCHEDULE, AGENT_LOG, AGENT_PRECHECK
lookup_agent_meta() {
  local agent_name="$1"
  for entry in "${AGENT_META[@]}"; do
    IFS='|' read -r name schedule log precheck <<< "$entry"
    if [[ "$name" == "$agent_name" ]]; then
      AGENT_SCHEDULE="$schedule"
      AGENT_LOG="$log"
      AGENT_PRECHECK="$precheck"
      return 0
    fi
  done
  return 1
}

# Run pre-check for an agent. Returns 1 if agent should be skipped.
run_precheck() {
  local precheck="$1"
  case "$precheck" in
    "")
      return 0
      ;;
    test-notifications)
      print_section "Testing notification system..."
      if osascript -e 'display notification "Dotfiles automation is now active" with title "Setup Complete"' 2>/dev/null; then
        printf "  "
        print_success "Notification test passed"
      else
        printf "  "
        print_warning "Notification test failed - check System Preferences > Notifications"
      fi
      return 0
      ;;
    check-keychain)
      if ! bash "$DOTFILES/setup/check-keychain.sh" --no-color; then
        print_error "Keychain requirements not satisfied"
        return 1
      fi
      return 0
      ;;
    check-vault)
      if [[ ! -d "$DOTFILES_OBSIDIAN_REPO_PATH" ]]; then
        print_warning "Obsidian vault not found at $DOTFILES_OBSIDIAN_REPO_PATH"
        return 1
      fi
      return 0
      ;;
    check-lmstudio)
      if [[ ! -x "$HOME/.lmstudio/bin/lms" ]]; then
        print_warning "LM Studio CLI not found at ~/.lmstudio/bin/lms"
        return 1
      fi
      return 0
      ;;
  esac
}

# Setup a single agent: create log dir, run precheck, install, verify.
setup_agent() {
  local agent_name="$1"

  if ! lookup_agent_meta "$agent_name"; then
    print_error "Unknown agent: $agent_name"
    return 1
  fi

  print_header "Setting Up: $agent_name"

  local log_dir="$HOME/.local/log"
  mkdir -p "$log_dir"

  if [[ -n "$AGENT_PRECHECK" ]]; then
    if ! run_precheck "$AGENT_PRECHECK"; then
      printf '\n'
      return 1
    fi
    printf '\n'
  fi

  print_section "Installing LaunchD agent..."
  if "$LAUNCHD_MANAGER" install "$agent_name"; then
    printf "  "
    print_success "Agent installed via launchd-manager"
  else
    printf "  "
    print_error "Failed to install agent"
    return 1
  fi

  printf '\n'
  print_section "Verification:"
  if launchctl print "gui/$(id -u)/$(agent_label "$agent_name")" >/dev/null 2>&1; then
    printf "  "
    print_success "Agent is running"
  else
    printf "  "
    print_error "Agent failed to load"
    return 1
  fi

  printf '\n'
  print_info "Schedule: $AGENT_SCHEDULE"
  print_info "Logs: $log_dir/$AGENT_LOG"
  print_info "Check status: make ops-status"
  printf '\n'
}

# agent_label from launchd/common.sh — inline to avoid sourcing the full file
agent_label() {
  printf 'com.user.%s' "$1"
}

setup_all() {
  print_header "Setting Up All Automations"
  printf '\n'

  local failed=0
  local skipped=0
  local installed=0

  # Always install core agents
  for agent in "${CORE_AGENTS[@]}"; do
    if setup_agent "$agent"; then
      installed=$((installed + 1))
    else
      failed=$((failed + 1))
    fi
  done

  # Conditionally install optional agents
  for optional in obsidian-sync lmstudio-server; do
    if ! lookup_agent_meta "$optional"; then
      continue
    fi
    if run_precheck "$AGENT_PRECHECK" 2>/dev/null; then
      if setup_agent "$optional"; then
        installed=$((installed + 1))
      else
        failed=$((failed + 1))
      fi
    else
      print_info "Skipped $optional (pre-check not satisfied)"
      skipped=$((skipped + 1))
    fi
  done

  printf '\n'
  print_header "Summary"
  print_success "Installed: $installed"
  if [[ $skipped -gt 0 ]]; then
    print_info "Skipped: $skipped (optional agents)"
  fi
  if [[ $failed -gt 0 ]]; then
    print_error "Failed: $failed"
    exit 1
  fi
}

main() {
  parse_args "$@"

  if [[ ! -x "$LAUNCHD_MANAGER" ]]; then
    print_error "launchd-manager script not found or not executable: $LAUNCHD_MANAGER"
    exit 1
  fi

  if [[ "$TARGET" == "setup-all" ]]; then
    setup_all
  else
    local agent_name
    agent_name="$(target_to_agent "$TARGET")"
    setup_agent "$agent_name"
  fi
}

main "$@"
