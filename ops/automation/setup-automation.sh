#!/usr/bin/env bash
# Setup LaunchD automation for managed dotfiles tasks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/env.sh"
dotfiles_load_env "$DOTFILES"
LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"

MANAGER="$DOTFILES/ops/automation/launchd-manager.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] <target>

Targets:
  backup         Setup backup automation
  doctor         Setup health monitoring
  repo-update    Setup repository updates
  obsidian-sync  Setup Obsidian vault sync
  lmstudio       Setup LM Studio server
  log-cleanup    Setup log rotation
  brew-audit     Setup Brewfile drift detection
  weekly-digest  Setup weekly digest
  setup-all      Setup all profile-appropriate automations
EOF
}

show_help_if_requested usage "$@"

TARGET=""
for arg in "$@"; do
  case "$arg" in
    --no-color) ;;
    backup|doctor|repo-update|obsidian-sync|lmstudio|log-cleanup|brew-audit|weekly-digest|setup-all) TARGET="$arg" ;;
    *) print_error "Unknown argument: $arg"; usage; exit 1 ;;
  esac
done
[[ -z "$TARGET" ]] && { usage; exit 1; }

# Map friendly names to agent names
resolve_agent() {
  case "$1" in
    lmstudio) echo "lmstudio-server" ;; doctor) echo "dotfiles-doctor" ;;
    backup) echo "dotfiles-backup" ;; *) echo "$1" ;;
  esac
}

# Pre-checks for optional agents
precheck() {
  case "$1" in
    obsidian-sync) [[ -d "$DOTFILES_OBSIDIAN_REPO_PATH" ]] || { print_warning "Obsidian vault not found"; return 1; } ;;
    lmstudio-server) [[ -x "$HOME/.lmstudio/bin/lms" ]] || { print_warning "LM Studio CLI not found"; return 1; } ;;
    repo-update) bash "$DOTFILES/setup/check-keychain.sh" --no-color 2>/dev/null || { print_warning "Keychain check failed"; return 1; } ;;
  esac
}

setup_agent() {
  local agent="$1"
  precheck "$agent" || return 1
  "$MANAGER" install "$agent"
}

if [[ "$TARGET" == "setup-all" ]]; then
  print_header "Setting Up All Automations"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
  ok=0 fail=0 skip=0
  while IFS= read -r agent_info; do
    [[ -n "$agent_info" ]] || continue
    IFS=':' read -r agent _desc <<< "$agent_info"
    if precheck "$agent" 2>/dev/null; then
      if setup_agent "$agent"; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
    else
      skip=$((skip + 1))
    fi
  done < <(profile_agent_infos)
  printf '\n'
  print_success "Installed: $ok"
  if [[ $skip -gt 0 ]]; then print_info "Skipped: $skip (optional)"; fi
  if [[ $fail -gt 0 ]]; then print_error "Failed: $fail"; exit 1; fi
else
  setup_agent "$(resolve_agent "$TARGET")"
fi
