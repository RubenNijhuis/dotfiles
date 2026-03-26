#!/usr/bin/env bash
# Remove common macOS built-in apps.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/cli.sh"

DRY_RUN=false
AUTO_YES=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--dry-run] [--yes]

Remove common macOS bloatware apps (Tips, Chess, Stocks, etc.).
EOF
}

parse_standard_args usage --accept-dry-run "$@"
has_flag "--yes" "$@" && AUTO_YES=true

BLOATWARE=(
  "/System/Applications/Tips.app"
  "/System/Applications/Chess.app"
  "/System/Applications/Stickies.app"
  "/System/Applications/Stocks.app"
  "/System/Applications/News.app"
  "/System/Applications/Freeform.app"
  "/Applications/GarageBand.app"
  "/Applications/iMovie.app"
)

# Find which apps are present
present=()
for app in "${BLOATWARE[@]}"; do
  [[ -d "$app" || -L "$app" ]] && present+=("$app")
done

if [[ ${#present[@]} -eq 0 ]]; then
  print_success "No bloatware found"
  exit 0
fi

print_header "Remove Bloatware"
print_info "Found ${#present[@]} app(s) to remove:"
for app in "${present[@]}"; do printf "  %s\n" "$(basename "$app")"; done
printf '\n'

if $DRY_RUN; then
  print_info "Dry run — no apps removed"
  exit 0
fi

if ! $AUTO_YES; then
  confirm "Remove these apps? [y/N] " || { print_info "Cancelled"; exit 0; }
fi

for app in "${present[@]}"; do
  if [[ "$app" == /System/* ]]; then
    if sudo rm -rf "$app" 2>/dev/null; then
      print_success "Removed $(basename "$app")"
    else
      print_warning "Failed to remove $(basename "$app") (SIP may be enabled)"
    fi
  else
    rm -rf "$app"
    print_success "Removed $(basename "$app")"
  fi
done
