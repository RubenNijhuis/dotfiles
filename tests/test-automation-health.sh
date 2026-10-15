#!/usr/bin/env bash
# Current launchd results must not be confused with append-only log history.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/health/doctor.sh" --no-color

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
out_log="$fixture/out.log"
err_log="$fixture/err.log"
report="$fixture/report.txt"
printf 'Historical network failure\n' > "$err_log"
touch -t 202601010900 "$err_log"
printf 'Apple updates: review System Settings\n' > "$out_log"
printf 'No updates found\n' > "$report"
success=$'state = not running\nruns = 3\nlast exit code = 0'

expect_status() {
  local expected="$1" snapshot="$2" actual
  actual=$(_agent_run_status "$snapshot" "$out_log" "$err_log" "$report")
  [[ "$actual" == "$expected" ]] || {
    printf 'Expected %s, got %s\n' "$expected" "$actual" >&2
    exit 1
  }
}

expect_status 'ok|last run succeeded' "$success"
expect_status 'info|running; previous result is not current' \
  $'state = running\nruns = 4\nlast exit code = 0'
expect_status 'warn|not run yet' $'state = not running\nruns = 0'
expect_status 'error|last run exited 1' \
  $'state = not running\nruns = 4\nlast exit code = 1'
expect_status 'error|last run terminated by signal 9' \
  $'state = not running\nruns = 4\nlast terminating signal = 9'
expect_status 'warn|no completed run result available' $'state = waiting\nruns = 1'
expect_status 'warn|no completed run result available' ''
expect_status 'warn|no completed run result available' $'last exit code = 0'

touch -t 202701010900 "$err_log"
expect_status 'warn|last run exited 0; newer stderr needs review' "$success"
printf 'Checks failed: Nix check\n' > "$report"
expect_status 'error|update report contains failed checks' "$success"
expect_status 'info|running; previous result is not current' \
  $'state = running\nruns = 4\nlast exit code = 0'
rm "$report"
expect_status 'warn|last run exited 0; no update report' "$success"
printf 'automation-health: all checks passed\n'
