#!/usr/bin/env bash
# Verify health checks resolve both global Git locations, not repository overrides.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/health/checks/core.sh"

developer_root() { printf '/nonexistent-dotfiles-health-test\n'; }
add_suggestion() { :; }
record_result() { actual_result="$2"; }
git() {
  [[ "$1" == -C && "$2" == / && "$3" == config ]] || return 9
  case "$4" in
    --get) [[ "$test_case" != missing-identity ]] ;;
    --get-regexp) [[ "$test_case" != missing-includes ]] ;;
    *) return 9 ;;
  esac
}

for test_case in complete missing-identity missing-includes; do
  expected_result=2
  [[ "$test_case" != complete ]] || expected_result=0
  actual_result=-1
  check_git
  [[ "$actual_result" == "$expected_result" ]] || {
    printf 'FAIL: Git health case %s returned %s\n' "$test_case" "$actual_result"
    exit 1
  }
done
echo 'PASS: Git health checks resolve configuration outside repositories'
