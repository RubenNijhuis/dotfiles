#!/usr/bin/env bash
# Verify health checks resolve both global Git locations, not repository overrides.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/health/checks/core.sh"

developer_root() { printf '/nonexistent-dotfiles-health-test\n'; }
add_suggestion() { :; }
record_result() { actual_result="$2"; }
signing_format=ssh
# shellcheck disable=SC2329 # Invoked indirectly by the sourced check_git.
git() {
  [[ "$1" == -C && "$2" == / && "$3" == config ]] || return 9
  case "$4" in
    --get)
      case "${5:-}" in
        gpg.format) printf '%s\n' "$signing_format" ;;
        user.signingkey)
          [[ "$test_case" != missing-selection ]] || return 1
          printf 'selected-fingerprint\n'
          ;;
        gpg.program) return 1 ;;
        *) [[ "$test_case" != missing-identity ]] ;;
      esac
      ;;
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

# This guard must not inspect keys, request a passphrase, or try a GPG signature.
# shellcheck disable=SC2329 # Must remain uncalled by check_gpg with SSH signing.
gpg() { echo 'FAIL: SSH signing touched the GPG keyring' >&2; exit 9; }
actual_result=-1
check_gpg
[[ "$actual_result" == 0 ]]
unset -f gpg
echo 'PASS: SSH Git signing does not require a second GPG identity'

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export GNUPGHOME="$fixture/gnupg"
signing_format=openpgp
get_preference() { printf 'yes\n'; }
# shellcheck disable=SC2329 # Invoked indirectly by the sourced check_gpg.
gpg() {
  [[ "$*" == '--batch --no-tty --with-colons --list-secret-keys selected-fingerprint' ]] || {
    echo 'FAIL: GPG health attempted signing or inspected an unrelated key' >&2
    return 9
  }
  [[ "$test_case" != missing-key ]] || return 1
  printf 'sec:u:255:22:fixture-key:::::::::\n'
}
for test_case in available missing-selection missing-key; do
  expected_result=0
  [[ "$test_case" != missing-selection ]] || expected_result=1
  [[ "$test_case" != missing-key ]] || expected_result=2
  actual_result=-1
  check_gpg
  [[ "$actual_result" == "$expected_result" ]] || {
    printf 'FAIL: GPG health case %s returned %s\n' "$test_case" "$actual_result"
    exit 1
  }
done
export -f git gpg
export signing_format test_case
for test_case in available missing-selection missing-key; do
  expected_result=0
  [[ "$test_case" == available ]] || expected_result=1
  if bash "$repo_root/setup/generate-gpg-keys.sh" --no-color >/dev/null 2>&1; then
    actual_result=0
  else
    actual_result=$?
  fi
  [[ "$actual_result" == "$expected_result" ]] || {
    printf 'FAIL: GPG setup case %s returned %s\n' "$test_case" "$actual_result"
    exit 1
  }
done
unset -f gpg git
echo 'PASS: OpenPGP health checks only the selected key metadata without signing'
echo 'PASS: GPG setup checks readiness without key generation or Git configuration writes'

# Recovery checks run in a disposable repository; no real index, keys, or
# network operations. A missing upstream must never look like a saved copy.
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
