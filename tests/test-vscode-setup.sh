#!/usr/bin/env bash
# Check extension reconciliation without touching the real VS Code profile.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/bin"
export VSCODE_TEST_ROOT="$test_root" VSCODE_TEST_REPO="$repo_root"

# Keep the mock derived from the one real manifest, not a duplicate ID list.
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  --list-extensions)' \
  '    [[ "${VSCODE_TEST_MODE:-}" != list-failure ]] || exit 7' \
  '    awk "!/^[[:space:]]*#/ && NF {print \$1}" "$VSCODE_TEST_REPO/nix/config/vscode/extensions.txt" | while read -r ext; do' \
  '      [[ "${VSCODE_TEST_MODE:-}" == complete || "$ext" != ms-vscode-remote.remote-containers ]] && printf "%s\n" "$ext"' \
  '    done ;;' \
  '  --install-extension)' \
  '    printf "%s\n" "$2" >> "$VSCODE_TEST_ROOT/installs"' \
  '    [[ "${VSCODE_TEST_MODE:-}" != install-failure ]] ;;' \
  '  *) exit 8 ;;' \
  'esac' > "$test_root/bin/code"
chmod +x "$test_root/bin/code"
export PATH="$test_root/bin:$PATH"

run_case() {
  local expected="$1" mode="$2" result=0
  shift 2
  VSCODE_TEST_MODE="$mode" bash "$repo_root/setup/vscode-setup.sh" "$@" \
    > "$test_root/output" 2>&1 || result=$?
  if [[ "$result" != "$expected" ]]; then
    cat "$test_root/output"
    printf 'FAIL: mode=%s expected=%s actual=%s\n' "$mode" "$expected" "$result"
    exit 1
  fi
}

run_case 0 complete --check
run_case 0 complete
run_case 1 missing --check
run_case 0 missing --dry-run
run_case 1 list-failure
[[ ! -e "$test_root/installs" ]] # inspection/preview never install
run_case 1 install-failure
run_case 0 missing
[[ "$(wc -l < "$test_root/installs" | tr -d ' ')" == 2 ]]
[[ "$(sort -u "$test_root/installs")" == ms-vscode-remote.remote-containers ]]
echo 'PASS: VS Code manifest check, preview, idempotence, and failure propagation'
