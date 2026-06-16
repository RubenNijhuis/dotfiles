#!/usr/bin/env bash
# Helpers for buffered-parallel execution: run a set of named tasks
# concurrently with each task's stdout/stderr captured to a buffer file
# and its exit code to a sibling .rc file. Output can then be replayed
# in a deterministic order regardless of which task finished first.
#
# This is the shared implementation behind make doctor, make update,
# the pre-push hook, make maint-check, and the parallel test runner.
# Source this file; do not execute.
#
# Usage:
#   tmp="$(parallel_tmpdir my-thing)"
#   trap 'rm -rf "$tmp"' EXIT
#   parallel_spawn "$tmp" repos   bash ops/update-repos.sh --compact
#   parallel_spawn "$tmp" brew    update_homebrew
#   parallel_wait
#   parallel_replay "$tmp" repos brew
#   if [[ "$(parallel_rc "$tmp" brew)" != "0" ]]; then ...
#
# parallel_spawn accepts ANY shell-callable as the command — a function,
# script, builtin, or compound command — followed by its args. The caller
# remains responsible for ordering, naming, and result aggregation; this
# library only owns the spawn/capture/wait primitives.

# Create a tempdir for a parallel run. Caller must clean it up.
parallel_tmpdir() {
  local label="${1:-parallel}"
  mktemp -d "${TMPDIR:-/tmp}/dotfiles-${label}.XXXXXX"
}

# Spawn a named task in the background. Writes:
#   $tmp/$name.out — captured stdout+stderr
#   $tmp/$name.rc  — exit code as a decimal string
#
# Usage: parallel_spawn <tmp> <name> <cmd> [args...]
parallel_spawn() {
  local tmp="$1" name="$2"
  shift 2
  (
    if "$@" >"$tmp/$name.out" 2>&1; then
      printf '0\n' > "$tmp/$name.rc"
    else
      printf '%s\n' "$?" > "$tmp/$name.rc"
    fi
  ) &
}

# Wait for all spawned tasks. Thin alias kept for readability at call sites.
parallel_wait() {
  wait
}

# Replay buffered output for the given task names in the order provided.
# Missing buffers are skipped silently — they indicate a spawn that never ran.
parallel_replay() {
  local tmp="$1"
  shift
  local name
  for name in "$@"; do
    [[ -f "$tmp/$name.out" ]] && cat "$tmp/$name.out"
  done
}

# Read a task's exit code. Returns "1" if the rc file is missing.
parallel_rc() {
  local tmp="$1" name="$2"
  cat "$tmp/$name.rc" 2>/dev/null || printf '1\n'
}

# Convenience: count failures across a list of task names.
parallel_failures() {
  local tmp="$1"
  shift
  local name rc total=0
  for name in "$@"; do
    rc="$(parallel_rc "$tmp" "$name")"
    [[ "$rc" != "0" ]] && total=$((total + 1))
  done
  printf '%d\n' "$total"
}
