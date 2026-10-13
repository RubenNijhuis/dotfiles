#!/usr/bin/env bash
# Check extension reconciliation without touching the real VS Code profile.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/bin" "$test_root/extensions"
export VSCODE_TEST_ROOT="$test_root" VSCODE_TEST_REPO="$repo_root"

# Keep the mock derived from the one real manifest, not a duplicate ID list.
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  --list-extensions)' \
  '    [[ "${VSCODE_TEST_MODE:-}" != list-failure ]] || exit 7' \
  '    missing_id=ms-vscode-remote.remote-containers' \
  '    [[ "${VSCODE_TEST_MODE:-}" != mixed-case ]] || missing_id=biomejs.biome' \
  '    awk "!/^[[:space:]]*#/ && NF {print \$1}" "$VSCODE_TEST_REPO/nix/config/vscode/extensions.txt" | while read -r ext; do' \
  '      case "${VSCODE_TEST_MODE:-}" in missing|install-failure|mixed-case) [[ "$ext" != "$missing_id" || -f "$VSCODE_TEST_ROOT/repaired" ]] || continue ;; esac' \
  '      [[ "${VSCODE_TEST_MODE:-}" != mixed-case ]] || ext=$(printf "%s" "$ext" | tr "[:lower:]" "[:upper:]")' \
  '      printf "%s\n" "$ext"' \
  '    done ;;' \
  '  --locate-extension)' \
  '    [[ "${VSCODE_TEST_MODE:-}" != locate-failure ]] || exit 9' \
  '    if [[ "${VSCODE_TEST_MODE:-}" == unknown-root ]]; then printf "%s\n" "$VSCODE_TEST_ROOT/unavailable/$2"; else printf "%s\n" "$VSCODE_TEST_ROOT/extensions/$2"; fi ;;' \
  '  --install-extension)' \
  '    printf "%s\n" "$*" >> "$VSCODE_TEST_ROOT/installs"' \
  '    [[ "${VSCODE_TEST_MODE:-}" != install-failure ]] || exit 10' \
  '    touch "$VSCODE_TEST_ROOT/repaired"' \
  '    if [[ "${VSCODE_TEST_MODE:-}" != false-success ]]; then mkdir -p "$VSCODE_TEST_ROOT/extensions/$2"; printf "{}\n" > "$VSCODE_TEST_ROOT/extensions/$2/package.json"; fi ;;' \
  '  *) exit 8 ;;' \
  'esac' > "$test_root/bin/code"
chmod +x "$test_root/bin/code"
export PATH="$test_root/bin:$PATH"

run_case() {
  local expected="$1" mode="$2" result=0
  shift 2
  # Each case starts with clean mock payloads and no repair marker.
  rm -f "$test_root/repaired"
  while read -r ext _; do
    case "$ext" in ''|\#*) continue ;; esac
    mkdir -p "$test_root/extensions/$ext"
    printf '{}\n' > "$test_root/extensions/$ext/package.json"
  done < "$repo_root/nix/config/vscode/extensions.txt"
  case "$mode" in
    missing|install-failure|stale|false-success)
      rm -f "$test_root/extensions/ms-vscode-remote.remote-containers/package.json" ;;
    mixed-case) rm -f "$test_root/extensions/biomejs.biome/package.json" ;;
  esac
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
run_case 1 locate-failure
run_case 1 locate-failure --check
run_case 1 unknown-root --dry-run
run_case 1 stale --check
run_case 0 stale --dry-run
[[ ! -e "$test_root/installs" ]] # inspection/preview never install
run_case 1 install-failure
run_case 0 missing
run_case 0 stale
run_case 1 false-success
[[ "$(wc -l < "$test_root/installs" | tr -d ' ')" == 4 ]]
[[ "$(sort -u "$test_root/installs")" == $'--install-extension ms-vscode-remote.remote-containers\n--install-extension ms-vscode-remote.remote-containers --force' ]]
rm -f "$test_root/installs"
run_case 0 mixed-case
[[ "$(cat "$test_root/installs")" == '--install-extension biomejs.biome' ]]
echo 'PASS: VS Code registration/payload checks, read-only preview, repair and verification'
