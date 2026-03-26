#!/usr/bin/env bash
# Shared utility helpers for dotfiles scripts.

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

# Send a macOS notification. No-op on non-macOS or missing osascript.
# Usage: notify <title> <message>
notify() {
  local title="$1" message="$2"
  command -v osascript >/dev/null 2>&1 || return 0
  osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1 || true
}

# Return 0 if network is reachable, 1 otherwise. Timeout: 3s.
# Usage: require_network [host]
require_network() {
  local host="${1:-github.com}"
  /sbin/ping -c1 -W3 "$host" >/dev/null 2>&1
}

# Retry a command up to N times with exponential backoff.
# Usage: retry <max_attempts> <command...>
retry() {
  local max="$1"; shift
  local attempt=1 delay=5
  while [[ $attempt -le $max ]]; do
    if "$@"; then return 0; fi
    [[ $attempt -eq $max ]] && return 1
    sleep $delay
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
}

# Delete log files older than N days. Default: 30 days.
# Usage: rotate_logs [log_dir] [max_days]
rotate_logs() {
  local log_dir="${1:-$HOME/.local/log}"
  local max_days="${2:-30}"
  find "$log_dir" -name "*.log" -mtime +"$max_days" -delete 2>/dev/null || true
}

# Run a script with locking, logging, and notification.
# Usage: run_automation <lock_name> <script_path> <log_file> <task_label> [--notify-on-success] [-- script_args...]
run_automation() {
  local lock_name="$1" script_path="$2" log_file="$3" task_label="$4"
  shift 4
  local notify_on_success=false
  local script_args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --notify-on-success) notify_on_success=true; shift ;;
      --) shift; script_args=("$@"); break ;;
      *) script_args+=("$1"); shift ;;
    esac
  done

  acquire_lock "$lock_name" || exit 0
  mkdir -p "$(dirname "$log_file")"

  local output code
  set +e
  output=$(bash "$script_path" "${script_args[@]}" 2>&1)
  code=$?
  set -e

  log_msg "$log_file" "$task_label completed (exit=$code)" --quiet
  printf '%s\n' "$output" >> "$log_file"

  if [[ $code -ne 0 ]]; then
    notify "$task_label Failed" "Check logs: $log_file"
    exit "$code"
  elif [[ "$notify_on_success" == true ]]; then
    notify "$task_label" "Completed successfully"
  fi
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

# Export functions so they're available in subshells (e.g. GNU parallel).
export -f require_bash_version has_flag show_help_if_requested
export -f require_cmd count_broken_symlinks
export -f log_msg acquire_lock notify require_network
export -f retry rotate_logs run_automation confirm get_preference
