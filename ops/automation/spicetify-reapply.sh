#!/usr/bin/env bash
# Re-apply spicetify when Spotify auto-updates past the version captured in the
# spicetify backup. Run at login and daily by launchd.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/output.sh" "$@"

CHECK_ONLY=0
FORCE=0

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--check] [--force]

Detects drift between the installed Spotify version and the spicetify backup
version, then re-applies spicetify ("spicetify backup apply") when they differ.

Options:
  --check  Exit 0 if in sync, 1 if drift detected. Do not apply.
  --force  Re-apply regardless of detected drift.
EOF
}

parse_args() {
  show_help_if_requested usage "$@"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color) shift ;;
      --check)    CHECK_ONLY=1; shift ;;
      --force)    FORCE=1; shift ;;
      *) print_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done
}

spotify_app_path() {
  # Prefer the path spicetify is configured against; fall back to /Applications.
  local cfg="$HOME/.config/spicetify/config-xpui.ini"
  local resources
  if [[ -f "$cfg" ]]; then
    resources="$(awk -F'=' '/^spotify_path/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' "$cfg" || true)"
    if [[ -n "$resources" ]]; then
      # spotify_path points at .../Spotify.app/Contents/Resources
      printf '%s\n' "${resources%/Contents/Resources}"
      return
    fi
  fi
  printf '/Applications/Spotify.app\n'
}

read_spotify_version() {
  local app="$1"
  [[ -f "$app/Contents/Info.plist" ]] || return 1
  defaults read "$app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null
}

read_backup_version() {
  local cfg="$HOME/.config/spicetify/config-xpui.ini"
  [[ -f "$cfg" ]] || return 1
  awk -F'=' '
    /^\[Backup\]/ {inblock=1; next}
    /^\[/         {inblock=0}
    inblock && /^version/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}
  ' "$cfg"
}

main() {
  parse_args "$@"
  require_cmd spicetify "Install with: brew install spicetify-cli"

  local app spotify_v backup_v
  app="$(spotify_app_path)"

  if [[ ! -d "$app" ]]; then
    print_warning "Spotify not installed at $app — nothing to do"
    exit 0
  fi

  spotify_v="$(read_spotify_version "$app" || true)"
  backup_v="$(read_backup_version || true)"

  if [[ -z "$spotify_v" ]]; then
    print_error "Could not read Spotify version from $app"
    exit 1
  fi

  print_info "Spotify: ${spotify_v}    backup: ${backup_v:-<none>}"

  # The backup version often carries a git-hash suffix (e.g. "1.2.90.451.gb094...");
  # Spotify's CFBundleShortVersionString is the numeric prefix. Match on that.
  local drift=0
  if [[ -z "$backup_v" ]]; then
    drift=1
  elif [[ "$backup_v" != "$spotify_v" && "$backup_v" != "$spotify_v".* ]]; then
    drift=1
  fi

  if (( CHECK_ONLY )); then
    if (( drift )); then
      print_warning "Drift detected"
      exit 1
    fi
    print_success "In sync"
    exit 0
  fi

  if (( ! drift && ! FORCE )); then
    print_success "In sync — nothing to do"
    exit 0
  fi

  print_info "Re-applying spicetify"
  if ! spicetify backup apply; then
    print_error "spicetify backup apply failed"
    exit 1
  fi
  print_success "Spicetify re-applied for Spotify $spotify_v"
}

main "$@"
