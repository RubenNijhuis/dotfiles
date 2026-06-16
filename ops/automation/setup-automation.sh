#!/usr/bin/env bash
# Setup LaunchD automation for managed dotfiles tasks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"
source "$SCRIPT_DIR/../../lib/env.sh"
# shellcheck source=../../lib/automation-registry.sh
source "$SCRIPT_DIR/../../lib/automation-registry.sh"
dotfiles_load_env "$DOTFILES"
LAUNCHD_MANAGER_SOURCE_ONLY=1 source "$DOTFILES/ops/automation/launchd-manager.sh"

MANAGER="$DOTFILES/ops/automation/launchd-manager.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] <target>

Targets:
EOF
  # Build target list from manifest (single source of truth).
  while IFS='|' read -r name desc _default alias; do
    [[ -z "$name" ]] && continue
    if [[ -n "$alias" ]]; then
      printf '  %-18s %s (alias: %s)\n' "$name" "$desc" "$alias"
    else
      printf '  %-18s %s\n' "$name" "$desc"
    fi
  done < <(_automation_read_manifest)
  printf '  %-18s %s\n' "setup-all" "Setup all profile-appropriate automations"
}

show_help_if_requested usage "$@"

# Build valid-target set from manifest.
_valid_targets=$(printf '%s\n' "$(automation_setup_targets)" "setup-all")

TARGET=""
for arg in "$@"; do
  case "$arg" in
    --no-color) ;;
    *)
      if printf '%s\n' "$_valid_targets" | grep -qx "$arg"; then
        TARGET="$arg"
      else
        print_error "Unknown argument: $arg"; usage; exit 1
      fi
      ;;
  esac
done
[[ -z "$TARGET" ]] && { usage; exit 1; }

resolve_agent() { automation_resolve_alias "$1"; }

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
