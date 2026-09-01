#!/usr/bin/env bash
# Create the portable personal file structure. This intentionally never moves,
# removes, syncs, or overwrites personal data.
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0"
  echo "Creates the standard Files and Private directories without moving data."
  exit 0
fi

if [[ $# -gt 0 ]]; then
  echo "Usage: $0" >&2
  exit 2
fi

files_root="${DOTFILES_FILES_ROOT:-$HOME/Files}"
private_root="${DOTFILES_PRIVATE_ROOT:-$HOME/Private}"

case "$files_root" in
  ""|"/"|"$HOME")
    printf 'Refusing unsafe files root: %s\n' "${files_root:-<empty>}" >&2
    exit 1
    ;;
esac

case "$private_root" in
  ""|"/"|"$HOME")
    printf 'Refusing unsafe private root: %s\n' "${private_root:-<empty>}" >&2
    exit 1
    ;;
esac

mkdir -p \
  "$files_root/00 Inbox" \
  "$files_root/10 Projects" \
  "$files_root/20 Areas" \
  "$files_root/30 Resources" \
  "$files_root/40 Archive" \
  "$files_root/90 Shared"

mkdir -p \
  "$private_root/Credentials/Exports" \
  "$private_root/Identity" \
  "$private_root/Recovery Codes"
chmod 700 "$private_root" "$private_root/Credentials" \
  "$private_root/Credentials/Exports" "$private_root/Identity" \
  "$private_root/Recovery Codes"

printf 'Personal file structure is ready at %s\n' "$files_root"
printf 'Private local-only structure is ready at %s\n' "$private_root"
