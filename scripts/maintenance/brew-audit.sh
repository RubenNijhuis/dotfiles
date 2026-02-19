#!/usr/bin/env bash
# Audit Brewfiles to find missing or unused packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

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
require_cmd "brew" "Install Homebrew first: https://brew.sh" >/dev/null || {
  print_error "Homebrew is required"
  exit 1
}

print_header "Brewfile Audit"

# Get current profile
if [[ -f "$HOME/.config/dotfiles-profile" ]]; then
  PROFILE=$(cat "$HOME/.config/dotfiles-profile")
else
  PROFILE="unknown"
fi

print_info "Current profile: $PROFILE"
printf '\n'

# Get lists
INSTALLED_FORMULAE=$(brew list --formula | sort)
INSTALLED_CASKS=$(brew list --cask | sort)
INSTALLED_VSCODE=$(code --list-extensions 2>/dev/null | sort || echo "")

# Get declared packages
DECLARED_FORMULAE=$(cat "$DOTFILES/brew/Brewfile.common" "$DOTFILES/brew/Brewfile.$PROFILE" 2>/dev/null | \
  grep '^brew ' | sed 's/brew "\([^"]*\)".*/\1/' | sort)

DECLARED_CASKS=$(cat "$DOTFILES/brew/Brewfile.common" "$DOTFILES/brew/Brewfile.$PROFILE" 2>/dev/null | \
  grep '^cask ' | sed 's/cask "\([^"]*\)".*/\1/' | sort)

DECLARED_VSCODE=$(cat "$DOTFILES/brew/Brewfile.common" "$DOTFILES/brew/Brewfile.$PROFILE" 2>/dev/null | \
  grep '^vscode ' | sed 's/vscode "\([^"]*\)".*/\1/' | sort)

# Find packages installed but not in Brewfiles
print_section "Installed but not in Brewfiles:"
printf '\n'

UNDECLARED_FORMULAE=$(comm -23 <(echo "$INSTALLED_FORMULAE") <(echo "$DECLARED_FORMULAE") | \
  grep -v -E '^(ca-certificates|openssl|python|gettext|gmp|libffi|libyaml|mpdecimal|ncurses|readline|sqlite|xz|zlib|libidn|libsodium|pcre2|gnutls|nettle|libtasn1|p11-kit|unbound|libnghttp2|brotli|c-ares|libuv|libssh2|zstd|lz4|icu4c|llvm|llhttp|simdjson|z3|unibilium|libevent|libgit2|libvterm|lpeg|luajit|luv|msgpack|tree-sitter|utf8proc|libunistring|libusb|npth|libassuan|libgcrypt|libgpg-error|libksba|pinentry|ada-url|fmt|hdrhistogram_c|libnghttp3|libngtcp2|oniguruma|pkgconf|ruby|uvwasi|mlx|mlx-c|libiconv)' || true)

UNDECLARED_CASKS=$(comm -23 <(echo "$INSTALLED_CASKS") <(echo "$DECLARED_CASKS") || true)

UNDECLARED_VSCODE=$(comm -23 <(echo "$INSTALLED_VSCODE") <(echo "$DECLARED_VSCODE") || true)

if [[ -n "$UNDECLARED_FORMULAE" ]]; then
  print_subsection "Formulae:"
  echo "$UNDECLARED_FORMULAE" | while read -r pkg; do
    printf "  "
    print_warning "$pkg"
  done
  printf '\n'
else
  print_success "All formulae are declared"
  printf '\n'
fi

if [[ -n "$UNDECLARED_CASKS" ]]; then
  print_subsection "Casks:"
  echo "$UNDECLARED_CASKS" | while read -r pkg; do
    printf "  "
    print_warning "$pkg"
  done
  printf '\n'
else
  print_success "All casks are declared"
  printf '\n'
fi

if [[ -n "$UNDECLARED_VSCODE" ]]; then
  print_subsection "VS Code Extensions:"
  echo "$UNDECLARED_VSCODE" | while read -r ext; do
    printf "  "
    print_warning "$ext"
  done
  printf '\n'
else
  print_success "All VS Code extensions are declared"
  printf '\n'
fi

# Find packages declared but not installed
print_section "Declared but not installed:"
printf '\n'

MISSING_FORMULAE=$(comm -13 <(echo "$INSTALLED_FORMULAE") <(echo "$DECLARED_FORMULAE") || true)
MISSING_CASKS=$(comm -13 <(echo "$INSTALLED_CASKS") <(echo "$DECLARED_CASKS") || true)
MISSING_VSCODE=$(comm -13 <(echo "$INSTALLED_VSCODE") <(echo "$DECLARED_VSCODE") || true)

if [[ -n "$MISSING_FORMULAE" ]]; then
  print_subsection "Formulae:"
  echo "$MISSING_FORMULAE" | while read -r pkg; do
    printf "  "
    print_error "$pkg"
  done
  printf '\n'
else
  print_success "All declared formulae are installed"
  printf '\n'
fi

if [[ -n "$MISSING_CASKS" ]]; then
  print_subsection "Casks:"
  echo "$MISSING_CASKS" | while read -r pkg; do
    printf "  "
    print_error "$pkg"
  done
  printf '\n'
else
  print_success "All declared casks are installed"
  printf '\n'
fi

if [[ -n "$MISSING_VSCODE" ]]; then
  print_subsection "VS Code Extensions:"
  echo "$MISSING_VSCODE" | while read -r ext; do
    printf "  "
    print_error "$ext"
  done
  printf '\n'
else
  print_success "All declared VS Code extensions are installed"
  printf '\n'
fi

# Summary
print_section "Summary:"

# Count non-empty lines
TOTAL_UNDECLARED=0
[[ -n "$UNDECLARED_FORMULAE" ]] && TOTAL_UNDECLARED=$((TOTAL_UNDECLARED + $(echo "$UNDECLARED_FORMULAE" | grep -c .)))
[[ -n "$UNDECLARED_CASKS" ]] && TOTAL_UNDECLARED=$((TOTAL_UNDECLARED + $(echo "$UNDECLARED_CASKS" | grep -c .)))
[[ -n "$UNDECLARED_VSCODE" ]] && TOTAL_UNDECLARED=$((TOTAL_UNDECLARED + $(echo "$UNDECLARED_VSCODE" | grep -c .)))

TOTAL_MISSING=0
[[ -n "$MISSING_FORMULAE" ]] && TOTAL_MISSING=$((TOTAL_MISSING + $(echo "$MISSING_FORMULAE" | grep -c .)))
[[ -n "$MISSING_CASKS" ]] && TOTAL_MISSING=$((TOTAL_MISSING + $(echo "$MISSING_CASKS" | grep -c .)))
[[ -n "$MISSING_VSCODE" ]] && TOTAL_MISSING=$((TOTAL_MISSING + $(echo "$MISSING_VSCODE" | grep -c .)))

if [[ $TOTAL_UNDECLARED -gt 0 ]]; then
  print_warning "$TOTAL_UNDECLARED packages installed but not in Brewfiles"
  print_dim "  Run 'make brew-sync' to add them"
fi

if [[ $TOTAL_MISSING -gt 0 ]]; then
  print_error "$TOTAL_MISSING packages declared but not installed"
  print_dim "  Run 'brew bundle --file=brew/Brewfile.common && brew bundle --file=brew/Brewfile.$PROFILE'"
fi

if [[ $TOTAL_UNDECLARED -eq 0 ]] && [[ $TOTAL_MISSING -eq 0 ]]; then
  print_success "All packages are in sync!"
fi

if $CHECK_MODE && { [[ $TOTAL_UNDECLARED -gt 0 ]] || [[ $TOTAL_MISSING -gt 0 ]]; }; then
  exit 1
fi
