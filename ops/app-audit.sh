#!/usr/bin/env bash
# Read bundle metadata only; never launch, register, move, or uninstall apps.
set -euo pipefail

usage() {
  printf 'Usage: %s [--check] [application-directory ...]\n' "$0"
  printf 'Report app versions and duplicate bundle IDs; --check fails on duplicates.\n'
}
if [[ "${1:-}" == --help ]]; then usage; exit 0; fi
check=false
if [[ "${1:-}" == --check ]]; then check=true; shift; fi
for argument in "$@"; do
  case "$argument" in -*) printf 'Unknown argument: %s\n' "$argument" >&2; usage >&2; exit 2 ;; esac
done
if [[ $# == 0 ]]; then
  set -- /Applications "$HOME/Applications" \
    "$HOME/Applications/Home Manager Apps" /Applications/Nix\ Apps
fi

inventory() {
  local root sub app path identifier version
  # Include vendor folders (Resolve, rekordbox, Python) one level down, but
  # never descend into app bundles or their internal helper applications.
  local roots=("$@")
  for root in "$@"; do
    for sub in "$root/"*/; do
      [[ -d "$sub" && "$sub" != *.app/ ]] || continue
      roots+=("$sub")
    done
  done
  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    for app in "$root/"*.app; do
      [[ -f "$app/Contents/Info.plist" ]] || continue
      path="$(cd "$app" && pwd -P)"
      identifier="$(plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist" 2>/dev/null || true)"
      [[ -n "$identifier" ]] || continue
      version="$(plutil -extract CFBundleShortVersionString raw -o - "$app/Contents/Info.plist" 2>/dev/null || true)"
      printf '%s\t%s\t%s\n' "$identifier" "${version:-unknown}" "$path"
    done
  done
}

# Resolve symlink aliases and repeated roots before counting actual bundles.
records="$(inventory "$@" | sort -u)"
printf 'Bundle ID\tVersion\tPath\n%s\n' "$records"
duplicates="$(printf '%s\n' "$records" | awk -F '\t' '
  NF >= 3 { count[$1]++; paths[$1]=paths[$1] "\n  " $3 }
  END { for (id in count) if (count[id] > 1) print id paths[id] }
')"
if [[ -n "$duplicates" ]]; then
  printf '\nMultiple bundles with the same ID (review, not deletion targets):\n%s\n' "$duplicates"
  if "$check"; then exit 1; fi
else
  printf '\nNo duplicate bundle IDs in the inspected application directories.\n'
fi
