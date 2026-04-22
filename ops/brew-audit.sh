#!/usr/bin/env bash
# Audit Brewfiles to find missing or unused packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"
source "$SCRIPT_DIR/../lib/env.sh"
source "$SCRIPT_DIR/../lib/brew.sh"
dotfiles_load_env "$DOTFILES"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color] [--check]

Audit Brewfiles against currently installed formulae, casks, and VS Code extensions.

Options:
  --check   Exit non-zero when drift is found.
EOF
}

parse_args() {
  CHECK_MODE=false
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      --check)
        CHECK_MODE=true
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

parse_args "$@"
require_cmd "brew" "Install Homebrew first: https://brew.sh" || exit 1

print_header "Brewfile Audit"
print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
print_status_row "Tracked Brewfiles" info "$(brew_profile_summary)"

# -- Helpers --

extract_declared_entries() {
  local kind="$1"
  while IFS= read -r brewfile; do
    grep "^${kind} " "$brewfile" || true
  done < <(brewfile_paths "$DOTFILES") | while IFS= read -r line; do
    local raw
    raw=$(printf '%s\n' "$line" | sed "s/${kind} \"\\([^\"]*\\)\".*/\\1/")
    brew_normalize_entry_name "$kind" "$raw"
  done | sort -u
}

# Print a list of packages or a success message.
print_pkg_diff() {
  local label="$1" list="$2" printer="$3"
  if [[ -n "$list" ]]; then
    print_subsection "${label}:"
    while read -r pkg; do
      printf "  "
      "$printer" "$pkg"
    done <<< "$list"
    printf '\n'
  else
    print_success "All ${label,,} are declared"
    printf '\n'
  fi
}

count_lines() {
  if [[ -n "$1" ]]; then echo "$1" | grep -c .; else echo 0; fi
}

# -- Gather installed state --
# Exclude default homebrew/* taps — they don't need Brewfile entries
INSTALLED_TAPS=$(brew tap | grep -v '^homebrew/' | sort)
# Use brew leaves to get only explicitly installed formulae (not transitive deps)
# Strip tap prefixes (e.g. "user/tap/pkg" → "pkg") to match Brewfile short names
INSTALLED_FORMULAE=$(brew leaves --installed-on-request 2>/dev/null | sed 's|.*/||' | sort)
INSTALLED_CASKS=$(brew list --cask | sort)
INSTALLED_VSCODE=$(code --list-extensions 2>/dev/null | sort || echo "")

# -- Gather declared state --
DECLARED_TAPS=$(extract_declared_entries tap)
DECLARED_FORMULAE=$(extract_declared_entries brew)
DECLARED_CASKS=$(extract_declared_entries cask)
DECLARED_VSCODE=$(extract_declared_entries vscode)

# -- Installed but not in Brewfiles --
print_section "Installed but not in Brewfiles:"

UNDECLARED_TAPS=$(comm -23 <(echo "$INSTALLED_TAPS") <(echo "$DECLARED_TAPS") || true)
UNDECLARED_FORMULAE=$(comm -23 <(echo "$INSTALLED_FORMULAE") <(echo "$DECLARED_FORMULAE") || true)
UNDECLARED_CASKS=$(comm -23 <(echo "$INSTALLED_CASKS") <(echo "$DECLARED_CASKS") || true)
UNDECLARED_VSCODE=$(comm -23 <(echo "$INSTALLED_VSCODE") <(echo "$DECLARED_VSCODE") || true)

print_pkg_diff "Taps" "$UNDECLARED_TAPS" print_warning
print_pkg_diff "Formulae" "$UNDECLARED_FORMULAE" print_warning
print_pkg_diff "Casks" "$UNDECLARED_CASKS" print_warning
print_pkg_diff "VS Code Extensions" "$UNDECLARED_VSCODE" print_warning

# -- Declared but not installed --
print_section "Declared but not installed:"

# For missing check, use full install list (a declared package might be present as a dep)
ALL_INSTALLED_FORMULAE=$(brew list --formula | sort)

MISSING_TAPS=$(comm -13 <(echo "$INSTALLED_TAPS") <(echo "$DECLARED_TAPS") || true)
MISSING_FORMULAE=$(comm -13 <(echo "$ALL_INSTALLED_FORMULAE") <(echo "$DECLARED_FORMULAE") || true)
MISSING_CASKS=$(comm -13 <(echo "$INSTALLED_CASKS") <(echo "$DECLARED_CASKS") || true)
MISSING_VSCODE=$(comm -13 <(echo "$INSTALLED_VSCODE") <(echo "$DECLARED_VSCODE") || true)

print_pkg_diff "Taps" "$MISSING_TAPS" print_error
print_pkg_diff "Formulae" "$MISSING_FORMULAE" print_error
print_pkg_diff "Casks" "$MISSING_CASKS" print_error
print_pkg_diff "VS Code Extensions" "$MISSING_VSCODE" print_error

# -- Summary --
print_section "Summary:"

TOTAL_UNDECLARED=$(( $(count_lines "$UNDECLARED_TAPS") + $(count_lines "$UNDECLARED_FORMULAE") + $(count_lines "$UNDECLARED_CASKS") + $(count_lines "$UNDECLARED_VSCODE") ))
TOTAL_MISSING=$(( $(count_lines "$MISSING_TAPS") + $(count_lines "$MISSING_FORMULAE") + $(count_lines "$MISSING_CASKS") + $(count_lines "$MISSING_VSCODE") ))

# Strict drift checks (used by --check) cover taps, formulae, and casks only.
TOTAL_UNDECLARED_STRICT=$(( $(count_lines "$UNDECLARED_TAPS") + $(count_lines "$UNDECLARED_FORMULAE") + $(count_lines "$UNDECLARED_CASKS") ))
TOTAL_MISSING_STRICT=$(( $(count_lines "$MISSING_TAPS") + $(count_lines "$MISSING_FORMULAE") + $(count_lines "$MISSING_CASKS") ))

if [[ $TOTAL_UNDECLARED -gt 0 ]]; then
  print_warning "$TOTAL_UNDECLARED packages installed but not in Brewfiles"
  print_dim "  Run 'make brew-sync' to add them"
fi

if [[ $TOTAL_MISSING -gt 0 ]]; then
  print_error "$TOTAL_MISSING packages declared but not installed"
  print_dim "  Run 'make install' or brew bundle against the tracked Brewfiles"
fi

if [[ $TOTAL_UNDECLARED -eq 0 ]] && [[ $TOTAL_MISSING -eq 0 ]]; then
  print_success "All packages are in sync!"
fi

if [[ -n "$MISSING_VSCODE" || -n "$UNDECLARED_VSCODE" ]]; then
  print_warning "VS Code extension drift is warning-only and does not fail --check"
fi

if $CHECK_MODE && { [[ $TOTAL_UNDECLARED_STRICT -gt 0 ]] || [[ $TOTAL_MISSING_STRICT -gt 0 ]]; }; then
  notify "Brew Audit" "Brewfile drift detected — run make brew-sync"
  exit 1
fi
