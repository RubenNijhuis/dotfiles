#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/health/checks/security.sh"
declare -A results
record_result() { results["$1"]="$2"; }
add_suggestion() { :; }
# Commands are fixtures: no real service changes, update scans, or private reads.
# shellcheck disable=SC2329
uname() { echo "$test_os"; }
# shellcheck disable=SC2329
sw_vers() { echo "$test_version"; }
# shellcheck disable=SC2329
launchctl() {
  [[ "$*" == 'print-disabled system' ]] || return 9
  [[ "$test_case" != inaccessible ]] || return 1
  echo '"com.openssh.sshd" => disabled'
  [[ "$test_case" != enabled ]] || return 0
  echo '"com.apple.screensharing" => disabled'
}
# shellcheck disable=SC2329
netstat() {
  [[ "$test_case" != sockets-unavailable ]] || return 1
  if [[ "$test_case" == listener && "$*" == '-an -p tcp' ]]; then
    echo 'tcp6 0 0 *.5900 *.* LISTEN'
  elif [[ "$test_case" == udp && "$*" == '-an -p udp' ]]; then
    echo 'udp4 0 0 *.3283 *.*'
  fi
  return 0
}
# shellcheck disable=SC2329
plutil() {
  [[ "$test_case" != no-catalog ]] || return 1
  [[ "$test_case" != malformed ]] || { echo invalid-json; return 0; }
  printf '%s\n' '[{"Display Name":"Safari","Display Version":"27.0"},{"Display Name":"macOS","Display Version":"27.0.1"}'
  if [[ "$test_case" == pending ]]; then
    echo ',{"Display Name":"macOS Tahoe","Display Version":"26.7.1"}]'
  else
    echo ']'
  fi
}
test_os=Darwin
for test_case in closed enabled listener udp inaccessible sockets-unavailable vulnerable pending no-catalog malformed; do
  results=()
  test_version=26.7
  [[ "$test_case" != vulnerable ]] || test_version=26.5.2
  check_security
  expected=0
  case "$test_case" in enabled|listener|udp) expected=2;; inaccessible|sockets-unavailable) expected=1;; esac
  [[ "${results[Remote access]}" == "$expected" ]]
  expected=0
  case "$test_case" in vulnerable) expected=2;; pending|no-catalog|malformed) expected=1;; esac
  [[ "${results[macOS updates]}" == "$expected" ]]
done
for test_version in 26.6 26.6.0 26.6.1; do
  test_case=closed
  check_security
  expected=2
  [[ "$test_version" != 26.6.1 ]] || expected=0
  [[ "${results[macOS updates]}" == "$expected" ]]
done
test_os=Linux
results=()
check_security
[[ "${#results[@]}" == 0 ]]
# The launchd helper changes SCRIPT_DIR; quick mode must still find its checks.
test_os=Darwin test_case=closed test_version=26.7
export test_os test_case test_version
export -f uname launchctl netstat sw_vers plutil
summary=$(bash "$repo_root/health/doctor.sh" --quick --no-color 2>&1)
[[ "$summary" == *'Remote access'* && "$summary" == *'macOS updates'* ]]
[[ "$summary" != *'No such file or directory'* ]]
echo 'PASS: remote-access listeners, unknown states, security floor, cached updates, and Linux skip'
