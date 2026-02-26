#!/usr/bin/env bash
# Shared output formatting utilities for dotfiles scripts using tput
# Source this file in other scripts: source "$(dirname "$0")/lib/output.sh"

# Check for --no-color flag in arguments or if not a terminal
NO_COLOR_FLAG=false
for arg in "$@"; do
  if [[ "$arg" == "--no-color" ]]; then
    NO_COLOR_FLAG=true
    break
  fi
done

# Initialize colors using tput (portable and built-in)
if [[ -t 1 ]] && ! $NO_COLOR_FLAG && command -v tput &>/dev/null && [[ -n "${TERM:-}" ]]; then
  # Colors available
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  MAGENTA=$(tput setaf 5)
  CYAN=$(tput setaf 6)
  BOLD=$(tput bold)
  DIM=$(tput dim)
  NC=$(tput sgr0)  # Reset
else
  # No colors
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  MAGENTA=''
  CYAN=''
  BOLD=''
  DIM=''
  NC=''
fi

# Output helper functions
print_header() {
  printf '%s%s%s\n' "${BLUE}${BOLD}" "$1" "${NC}"
  printf '%s\n' "$(printf '=%.0s' $(seq 1 ${#1}))"
  printf '\n'
}

print_section() {
  printf '%s%s%s\n' "${BLUE}" "$1" "${NC}"
  printf '\n'
}

print_subsection() {
  printf '%s%s%s\n' "${CYAN}" "$1" "${NC}"
}

print_success() {
  printf '%s✓%s %s\n' "${GREEN}" "${NC}" "$1"
}

print_error() {
  printf '%s✗%s %s\n' "${RED}" "${NC}" "$1"
}

print_warning() {
  printf '%s⚠%s %s\n' "${YELLOW}" "${NC}" "$1"
}

print_info() {
  printf '%sℹ%s %s\n' "${BLUE}" "${NC}" "$1"
}

print_dim() {
  printf '%s%s%s\n' "${DIM}" "$1" "${NC}"
}

print_bullet() {
  printf '  • %s\n' "$1"
}

print_indent() {
  printf '    %s\n' "$1"
}

print_key_value() {
  local key="$1"
  local value="$2"
  printf '  %s%s:%s %s\n' "${BOLD}" "$key" "${NC}" "$value"
}

# Status indicators
status_ok() {
  printf '%s✓%s' "${GREEN}" "${NC}"
}

status_fail() {
  printf '%s✗%s' "${RED}" "${NC}"
}

status_warn() {
  printf '%s⚠%s' "${YELLOW}" "${NC}"
}

# Export functions and variables
export RED GREEN YELLOW BLUE CYAN MAGENTA BOLD DIM NC
export -f print_header print_section print_subsection
export -f print_success print_error print_warning print_info print_dim
export -f print_bullet print_indent print_key_value
export -f status_ok status_fail status_warn
