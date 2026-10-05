#!/usr/bin/env bash
# Verify health checks resolve both global Git locations, not repository overrides.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/health/checks/core.sh"

developer_root() { printf '/nonexistent-dotfiles-health-test\n'; }
add_suggestion() { :; }
record_result() { actual_result="$2"; }
# shellcheck disable=SC2329 # Invoked indirectly by the sourced check_git.
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

# Recovery checks run in a disposable repository; no real index, keys, or
# network operations. A missing upstream must never look like a saved copy.
unset -f git
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
git -C "$fixture" init --quiet
git -C "$fixture" config user.name Fixture
git -C "$fixture" config user.email fixture@example.invalid
git -C "$fixture" config commit.gpgsign false
git -C "$fixture" config core.hooksPath /dev/null
printf 'baseline\n' > "$fixture/example.txt"
git -C "$fixture" add example.txt
git -C "$fixture" commit --quiet -m baseline
if repo_recovery_counts "$fixture"; then
  echo 'FAIL: missing upstream reported recoverable'; exit 1
fi
git -C "$fixture" remote add origin https://example.invalid/recovery-test
git -C "$fixture" update-ref refs/remotes/origin/main HEAD
git -C "$fixture" branch --set-upstream-to=origin/main >/dev/null
[[ "$(repo_recovery_counts "$fixture")" == $'0\t0\t0' ]]
printf 'pending\n' >> "$fixture/example.txt"
[[ "$(repo_recovery_counts "$fixture")" == $'0\t0\t1' ]]
git -C "$fixture" add example.txt
git -C "$fixture" commit --quiet -m pending
[[ "$(repo_recovery_counts "$fixture")" == $'1\t0\t0' ]]
printf 'untracked\n' > "$fixture/new.txt"
[[ "$(repo_recovery_counts "$fixture")" == $'1\t0\t1' ]]
echo 'PASS: Git recovery detects unpublished commits and uncommitted work without network access'
