#!/usr/bin/env bash
# Reconcile the extension manifest without removing application-managed extras.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

CHECK_ONLY=false
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--check] [--dry-run]

Install VS Code extensions declared in nix/config/vscode/extensions.txt.
Skips extensions that are already installed.
--check reports missing extensions without installing; exits 1 on drift.
--dry-run previews missing installs without changing VS Code.
Undeclared extensions are left untouched. Installation failures exit 1.
EOF
}

show_help_if_requested usage "$@"
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=true ;;
    --dry-run) DRY_RUN=true ;;
    --no-color|--quiet) ;;
    *) print_error "Unknown argument: $arg"; usage; exit 1 ;;
  esac
done

DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
EXTENSIONS_FILE="$DOTFILES/nix/config/vscode/extensions.txt"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
  print_error "extensions.txt not found at $EXTENSIONS_FILE"
  exit 1
fi

if ! command -v code &>/dev/null; then
  print_error "'code' command not found. Is VS Code installed?"
  exit 1
fi

if ! installed_extensions=$(code --list-extensions); then
  print_error "Cannot inspect VS Code extensions; no installs attempted"
  exit 1
fi
installed_extensions=$(printf '%s\n' "$installed_extensions" | tr '[:upper:]' '[:lower:]')

print_section "Checking VS Code extension manifest"
failed=0
total=0
missing=0
while read -r ext _ || [[ -n "$ext" ]]; do
  case "$ext" in ''|\#*) continue ;; esac
  ext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
  if [[ ! "$ext" =~ ^[a-z0-9-]+\.[a-z0-9.-]+$ ]]; then
    print_error "Invalid extension ID: $ext"
    failed=$((failed + 1))
    continue
  fi
  total=$((total + 1))
  if printf '%s\n' "$installed_extensions" | grep -Fxq "$ext"; then
    continue
  fi
  missing=$((missing + 1))
  if $CHECK_ONLY || $DRY_RUN; then
    print_warning "Missing: $ext"
    continue
  fi
  if ! code --install-extension "$ext" >/dev/null 2>&1; then
    print_error "Failed: $ext"
    failed=$((failed + 1))
  fi
done < "$EXTENSIONS_FILE"

if [[ $failed -gt 0 ]] || { $CHECK_ONLY && [[ $missing -gt 0 ]]; }; then
  print_error "Extension check failed: $missing missing, $failed errors"
  exit 1
fi
if $DRY_RUN; then
  print_info "Preview: $missing/$total extensions need installation"
else
  print_success "All $total declared extensions are available"
fi
