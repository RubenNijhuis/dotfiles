#!/usr/bin/env bash
# Shared test assertion helpers and utilities.

# Global failure counter — incremented by assert helpers.
TEST_FAILURES=0

# Assert a command exits with the expected code.
# Usage: assert_exit <label> <expected_code> <command...>
assert_exit() {
  local label="$1" expected="$2"
  shift 2
  set +e
  "$@" >/dev/null 2>&1
  local actual=$?
  set -e
  if [[ "$actual" -ne "$expected" ]]; then
    print_error "FAIL($label): expected exit $expected, got $actual"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi
}

# Assert a command's combined output contains a pattern.
# Usage: assert_output_contains <label> <pattern> <command...>
assert_output_contains() {
  local label="$1" pattern="$2"
  shift 2
  set +e
  local output
  output=$("$@" 2>&1)
  set -e
  if ! printf '%s' "$output" | /usr/bin/grep -q "$pattern"; then
    print_error "FAIL($label): output missing '$pattern'"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi
}

# Print test summary and exit non-zero if any failures occurred.
# Usage: test_summary <suite_name>
test_summary() {
  local suite="$1"
  if [[ $TEST_FAILURES -gt 0 ]]; then
    print_error "$suite: $TEST_FAILURES test(s) failed"
    exit 1
  fi
  print_success "$suite: all checks passed"
}

# Create a temp directory and echo its path. Caller is responsible for cleanup.
# Usage: temp_home=$(make_temp_home)
make_temp_home() {
  mktemp -d
}
