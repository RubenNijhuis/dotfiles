#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/env.sh"
dotfiles_load_env "$DOTFILES"

SPICETIFY_DIR="$HOME/.config/spicetify"
SPICETIFY_CONFIG="$SPICETIFY_DIR/config-xpui.ini"
SPOTIFY_APP="/Applications/Spotify.app"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] <status|apply|restore>

Manage the local Spicetify setup used for Spotify theming.
EOF
}

require_spicetify() {
  require_cmd "spicetify" "Install with: brew install spicetify-cli" || exit 1
}

current_theme() {
  spicetify config current_theme 2>/dev/null || echo "unknown"
}

current_scheme() {
  spicetify config color_scheme 2>/dev/null || echo "unknown"
}

current_apps() {
  spicetify config custom_apps 2>/dev/null || echo ""
}

backup_state() {
  spicetify backup status 2>&1 || true
}

theme_root() {
  local theme_name
  theme_name="$(current_theme)"
  printf '%s/Themes/%s\n' "$SPICETIFY_DIR" "$theme_name"
}

print_status() {
  require_spicetify
  print_header "Spicetify Status"
  print_dim "Compact health check for Spotify theming and custom app wiring."
  printf '\n'

  local issues=0

  if [[ -d "$SPOTIFY_APP" ]]; then
    print_status_row "Spotify app" ok "$SPOTIFY_APP"
  else
    print_status_row "Spotify app" error "missing from /Applications"
    issues=$((issues + 1))
  fi

  if [[ -L "$SPICETIFY_CONFIG" ]]; then
    print_status_row "Config" ok "symlinked to repo config"
  elif [[ -f "$SPICETIFY_CONFIG" ]]; then
    print_status_row "Config" warn "local file is not repo-managed"
    issues=$((issues + 1))
  else
    print_status_row "Config" error "missing"
    issues=$((issues + 1))
  fi

  local theme_name scheme_name theme_path
  theme_name="$(current_theme)"
  scheme_name="$(current_scheme)"
  theme_path="$(theme_root)"
  if [[ -f "$theme_path/user.css" && -f "$theme_path/color.ini" ]]; then
    print_status_row "Theme" ok "$theme_name / $scheme_name"
  else
    print_status_row "Theme" error "$theme_name is missing repo-managed files"
    issues=$((issues + 1))
  fi

  local custom_apps
  custom_apps="$(current_apps)"
  if [[ -n "$custom_apps" ]]; then
    print_status_row "Custom apps" info "$custom_apps"
  else
    print_status_row "Custom apps" warn "none configured"
  fi

  if [[ "$custom_apps" == *"marketplace"* ]]; then
    if [[ -d "$SPICETIFY_DIR/CustomApps/marketplace" ]]; then
      print_status_row "Marketplace" ok "installed"
    else
      print_status_row "Marketplace" warn "configured but app files are missing"
      issues=$((issues + 1))
    fi
  fi

  local backup_output
  backup_output="$(backup_state)"
  if printf '%s' "$backup_output" | grep -q "A backup is available"; then
    print_status_row "Backup" ok "available"
  else
    print_status_row "Backup" warn "no reusable backup reported"
  fi

  print_next_steps \
    "Run: make spicetify-apply to re-apply the current theme" \
    "Run: make stow if repo-managed Spicetify files drifted"

  [[ $issues -eq 0 ]]
}

apply_spicetify() {
  require_spicetify
  print_header "Applying Spicetify"
  print_dim "Re-applies the current theme and custom apps without changing tracked config defaults."
  printf '\n'

  print_status_row "Theme" info "$(current_theme) / $(current_scheme)"
  if [[ "$(current_apps)" == *"marketplace"* && ! -d "$SPICETIFY_DIR/CustomApps/marketplace" ]]; then
    print_status_row "Marketplace" warn "configured but missing on disk"
  fi

  if spicetify apply; then
    print_status_row "Apply" ok "Spicetify applied successfully"
    print_next_steps "Open or restart Spotify if the UI does not refresh immediately."
    return 0
  fi

  print_status_row "Apply" error "Spicetify apply failed"
  return 1
}

restore_spicetify() {
  require_spicetify
  print_header "Restoring Spotify"
  print_dim "Restores the pre-Spicetify Spotify backup."
  printf '\n'

  if spicetify restore; then
    print_status_row "Restore" ok "Spotify restored"
    print_next_steps "Run: make spicetify-apply when you want the theme back."
    return 0
  fi

  print_status_row "Restore" error "restore failed"
  return 1
}

main() {
  show_help_if_requested usage "$@"

  local args=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --no-color|--help|-h) ;;
      *) args+=("$arg") ;;
    esac
  done

  [[ ${#args[@]} -gt 0 ]] || { usage; exit 1; }

  case "${args[0]}" in
    status)  print_status ;;
    apply)   apply_spicetify ;;
    restore) restore_spicetify ;;
    *)       print_error "Unknown command: ${args[0]}"; usage; exit 1 ;;
  esac
}

main "$@"
