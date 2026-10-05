#!/usr/bin/env bash
# Exercise argument safety, failure propagation, and shell portability.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
test_root="$(cd "$test_root" && pwd -P)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/home" "$test_root/project ; literal" "$test_root/bin"
cat > "$test_root/cases.sh" <<'CASES'
source "$WORKFLOW_REPO/nix/config/shell/functions.sh"
cmux() { printf '%s\n' "$@" > "$WORKFLOW_TMP/call"; return "${MOCK_CMUX_RC:-0}"; }
export CMUX_WORKSPACE_ID=test-workspace
proj "$WORKFLOW_TMP/project ; literal" || exit 1
printf '%s\n' new-workspace --cwd "$WORKFLOW_TMP/project ; literal" --name 'project ; literal' --focus true > "$WORKFLOW_TMP/expected"
cmp "$WORKFLOW_TMP/call" "$WORKFLOW_TMP/expected" || exit 1
MOCK_CMUX_RC=7
proj "$WORKFLOW_TMP/project ; literal"
[[ $? == 7 ]] || exit 1
unset MOCK_CMUX_RC
proj "$WORKFLOW_TMP/missing" >/dev/null 2>&1
[[ $? == 1 ]] || exit 1
notify-run sh -c 'exit 23' private-argument
[[ $? == 23 ]] || exit 1
printf '%s\n' notify --title 'sh finished' --body 'Exit status: 23' > "$WORKFLOW_TMP/expected"
cmp "$WORKFLOW_TMP/call" "$WORKFLOW_TMP/expected" || exit 1
MOCK_CMUX_RC=9
notify-run true
[[ $? == 0 ]] || exit 1
notify-run >/dev/null 2>&1
[[ $? == 2 ]] || exit 1
unset CMUX_WORKSPACE_ID
EDITOR=workflow-editor
proj "$WORKFLOW_TMP/project ; literal" || exit 1
[[ "$PWD" == "$WORKFLOW_TMP/project ; literal" ]] || exit 1
printf '%s\n' --new-window . > "$WORKFLOW_TMP/expected"
cmp "$WORKFLOW_TMP/editor" "$WORKFLOW_TMP/expected" || exit 1
CASES
cat > "$test_root/bin/workflow-editor" <<'EDITOR'
#!/bin/sh
printf '%s\n' "$@" > "$WORKFLOW_TMP/editor"
EDITOR
chmod +x "$test_root/bin/workflow-editor"
for test_shell in bash zsh; do
    if ! command -v "$test_shell" >/dev/null 2>&1; then
        echo "SKIP: $test_shell unavailable"
        continue
    fi
    HOME="$test_root/home" WORKFLOW_REPO="$repo_root" WORKFLOW_TMP="$test_root" \
        PATH="$test_root/bin:$PATH" "$test_shell" "$test_root/cases.sh"
    echo "PASS: terminal workflow ($test_shell)"
done
