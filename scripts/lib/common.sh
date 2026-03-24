#!/usr/bin/env bash
# Shared utility helpers for dotfiles scripts.

# Valid dotfiles profiles — single source of truth.
VALID_PROFILES=(personal work)

# Require a minimum bash version. macOS ships bash 3.2; Homebrew provides 5+.
# Usage: require_bash_version <major> [context]
require_bash_version() {
  local required="$1"
  local context="${2:-this script}"
  if [[ "${BASH_VERSINFO[0]:-0}" -lt "$required" ]]; then
    echo "Error: $context requires bash $required+ (current: ${BASH_VERSION:-unknown})" >&2
    echo "Install with: brew install bash" >&2
    exit 1
  fi
}

has_flag() {
  local needle="$1"
  shift || true

  local arg
  for arg in "$@"; do
    if [[ "$arg" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

show_help_if_requested() {
  local usage_fn="$1"
  shift || true

  if has_flag "--help" "$@" || has_flag "-h" "$@"; then
    "$usage_fn"
    exit 0
  fi
}

require_cmd() {
  local cmd="$1"
  local hint="${2:-Install $cmd and retry.}"

  if ! command -v "$cmd" &>/dev/null; then
    if declare -f print_error &>/dev/null; then
      print_error "Missing required command: $cmd" >&2
      printf '  %s\n' "$hint" >&2
    else
      echo "Missing required command: $cmd" >&2
      echo "$hint" >&2
    fi
    return 1
  fi
}

validate_profile() {
  local profile="$1"
  local valid
  for valid in "${VALID_PROFILES[@]}"; do
    if [[ "$profile" == "$valid" ]]; then
      return 0
    fi
  done
  local joined
  joined="$(IFS='|'; printf '%s' "${VALID_PROFILES[*]}")"
  echo "Invalid profile: '$profile' (expected $joined)" >&2
  return 1
}

# Count broken symlinks in a directory (default: $HOME, depth 1).
# Usage: count_broken_symlinks [dir] [maxdepth]
count_broken_symlinks() {
  local dir="${1:-$HOME}"
  local maxdepth="${2:-1}"
  local count=0
  while IFS= read -r link; do
    if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
      count=$((count + 1))
    fi
  done < <(find "$dir" -maxdepth "$maxdepth" -type l 2>/dev/null)
  printf '%d' "$count"
}

# Log a timestamped message to a file (and optionally stdout).
# Uses flock to prevent interleaved writes from parallel jobs.
# Usage: log_msg <log_file> <message> [--quiet]
log_msg() {
  local log_file="$1"
  local message="$2"
  local quiet="${3:-}"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  local line="[$timestamp] $message"

  mkdir -p "$(dirname "$log_file")"
  if command -v flock &>/dev/null; then
    local lock_file="${log_file}.lock"
    (
      flock -w 5 200 2>/dev/null || true
      printf '%s\n' "$line" >> "$log_file"
    ) 200>"$lock_file"
  else
    printf '%s\n' "$line" >> "$log_file"
  fi

  if [[ "$quiet" != "--quiet" ]]; then
    printf '%s\n' "$line"
  fi
}

# Acquire an exclusive lock to prevent concurrent script runs.
# Usage: acquire_lock <lock_name>
# Uses mkdir (atomic on all POSIX systems) with a stale-lock timeout of 1 hour.
# Returns 1 if another instance is already running.
acquire_lock() {
  local lock_name="$1"
  local lock_dir="/tmp/dotfiles-${lock_name}.lock"
  local stale_seconds=3600

  # Remove stale locks (older than 1 hour)
  if [[ -d "$lock_dir" ]]; then
    local lock_age
    lock_age=$(( $(date +%s) - $(stat -f %m "$lock_dir" 2>/dev/null || echo 0) ))
    if [[ $lock_age -gt $stale_seconds ]]; then
      rm -rf "$lock_dir"
    fi
  fi

  if ! mkdir "$lock_dir" 2>/dev/null; then
    if declare -f print_warning &>/dev/null; then
      print_warning "Another instance is already running ($lock_name)" >&2
    else
      echo "Another instance is already running ($lock_name)" >&2
    fi
    return 1
  fi

  # Store PID for diagnostics
  echo $$ > "$lock_dir/pid"

  # Clean up lock on exit (expand lock_dir now, not at signal time)
  # shellcheck disable=SC2064
  trap "rm -rf '${lock_dir}'" EXIT
}

confirm() {
  local prompt="$1"
  local default="${2:-N}"
  local answer

  read -rp "$prompt" answer

  if [[ -z "${answer:-}" ]]; then
    answer="$default"
  fi

  [[ "$answer" =~ ^[Yy]$ ]]
}

# Read a saved preference value from dotfiles-install-preferences.
# Returns the stored value, or the default if the file/key is absent.
get_preference() {
  local key="$1"
  local default="${2:-}"
  local prefs_file="$HOME/.config/dotfiles-install-preferences"
  if [[ -f "$prefs_file" ]]; then
    local value
    value=$(grep "^${key}=" "$prefs_file" 2>/dev/null | tail -1 | cut -d'"' -f2)
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return
    fi
  fi
  printf '%s' "$default"
}
