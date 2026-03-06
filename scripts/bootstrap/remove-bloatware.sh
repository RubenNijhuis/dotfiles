#!/usr/bin/env bash
# Remove macOS built-in apps that are rarely useful for developers.
# Only removes GUI applications — no system packages or frameworks.
# Some apps live in /System/Applications and may require sudo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

# ---------------------------------------------------------------------------
# Apps to remove
# Each entry is a path relative to / (so both /Applications and
# /System/Applications entries work uniformly).
# Edit this list to taste before running.
# ---------------------------------------------------------------------------
BLOATWARE_APPS=(
  "/System/Applications/Tips.app"
  "/System/Applications/Chess.app"
  "/System/Applications/Stickies.app"
  "/System/Applications/Stocks.app"
  "/System/Applications/News.app"
  "/System/Applications/Freeform.app"
  "/Applications/GarageBand.app"
  "/Applications/iMovie.app"
)

NON_INTERACTIVE=false
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [options]

Remove common macOS bloatware apps (GUI applications only).
Apps in /System/Applications require sudo; you will be prompted once.

Options:
  --yes        Skip confirmation prompts
  --dry-run    List apps to remove without actually removing them
  --no-color   Disable colour output
  --help, -h   Show this help
EOF
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes)
        NON_INTERACTIVE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --no-color)
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

# Returns 0 if the app exists (either as a directory or a symlink).
app_exists() {
  [[ -d "$1" ]] || [[ -L "$1" ]]
}

collect_present_apps() {
  local app
  PRESENT_APPS=()
  for app in "${BLOATWARE_APPS[@]}"; do
    if app_exists "$app"; then
      PRESENT_APPS+=("$app")
    fi
  done
}

print_app_list() {
  local app
  for app in "${PRESENT_APPS[@]}"; do
    print_dim "  - $(basename "$app")"
  done
}

needs_sudo() {
  local app="$1"
  [[ "$app" == /System/* ]]
}

remove_app() {
  local app="$1"

  if needs_sudo "$app"; then
    if sudo rm -rf "$app" 2>/dev/null; then
      return 0
    else
      return 1
    fi
  else
    if rm -rf "$app" 2>/dev/null; then
      return 0
    else
      # Retry with sudo for apps the current user cannot delete.
      if sudo rm -rf "$app" 2>/dev/null; then
        return 0
      else
        return 1
      fi
    fi
  fi
}

main() {
  parse_args "$@"
  print_header "macOS Bloatware Removal"

  collect_present_apps

  if [[ ${#PRESENT_APPS[@]} -eq 0 ]]; then
    print_success "No bloatware apps found — nothing to remove."
    return 0
  fi

  print_section "Apps to remove (${#PRESENT_APPS[@]} found):"
  print_app_list

  # Note about /System/Applications apps requiring sudo.
  local has_system=false
  local app
  for app in "${PRESENT_APPS[@]}"; do
    if needs_sudo "$app"; then
      has_system=true
      break
    fi
  done
  if $has_system; then
    print_warning "Some apps are in /System/Applications and require sudo."
    print_warning "You will be prompted for your password."
  fi

  if $DRY_RUN; then
    print_warning "DRY RUN: no apps were removed."
    return 0
  fi

  if ! $NON_INTERACTIVE; then
    if ! confirm "Remove these apps? [y/N] " "N"; then
      print_warning "Skipped."
      return 0
    fi
  fi

  printf '\n'
  print_section "Removing apps..."

  local removed=0 failed=0 failed_apps=()
  for app in "${PRESENT_APPS[@]}"; do
    local name
    name="$(basename "$app")"
    if remove_app "$app"; then
      print_success "$name removed"
      removed=$((removed + 1))
    else
      print_error "$name — could not remove (may require SIP to be disabled)"
      failed_apps+=("$name")
      failed=$((failed + 1))
    fi
  done

  printf '\n'
  if [[ $failed -eq 0 ]]; then
    print_success "Removed $removed app(s)."
  else
    print_success "Removed $removed app(s)."
    print_warning "$failed app(s) could not be removed:"
    for name in "${failed_apps[@]}"; do
      print_dim "  - $name"
    done
    print_dim "  To remove system-protected apps, disable SIP first."
    print_dim "  See: https://support.apple.com/en-us/102149"
  fi
}

main "$@"
