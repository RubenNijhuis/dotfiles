#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/first/Example.app/Contents" "$test_root/second/Example.app/Contents"
touch "$test_root/first/Example.app/Contents/Info.plist" "$test_root/second/Example.app/Contents/Info.plist"
# shellcheck disable=SC2329 # Exported into the audited child process.
plutil() {
  case "$2" in CFBundleIdentifier) printf 'org.example.app\n' ;; CFBundleShortVersionString) printf '1.2.3\n' ;; *) return 1 ;; esac
}
export -f plutil
bash "$ROOT_DIR/ops/app-audit.sh" --check "$test_root/first" "$test_root/first" > "$test_root/result"
ln -s "$test_root/first/Example.app" "$test_root/first/Alias.app"
bash "$ROOT_DIR/ops/app-audit.sh" --check "$test_root/first" > "$test_root/result"
if bash "$ROOT_DIR/ops/app-audit.sh" --check "$test_root/first" "$test_root/second" > "$test_root/result"; then
  echo 'FAIL: distinct copies of the same app were not detected' >&2; exit 1
fi
grep -q 'Multiple bundles' "$test_root/result"
bash "$ROOT_DIR/ops/app-audit.sh" --check "$test_root/absent" > "$test_root/result"
mkdir -p "$test_root/nested/Vendor/Example.app/Contents"
touch "$test_root/nested/Vendor/Example.app/Contents/Info.plist"
if bash "$ROOT_DIR/ops/app-audit.sh" --check "$test_root/first" "$test_root/nested" > "$test_root/result"; then
  echo 'FAIL: nested vendor app was not detected' >&2; exit 1
fi
mkdir -p "$test_root/first/Example.app/Internal.app/Contents"
touch "$test_root/first/Example.app/Internal.app/Contents/Info.plist"
bash "$ROOT_DIR/ops/app-audit.sh" --check "$test_root/first" > "$test_root/result"
echo 'PASS: real app copies detected; aliases, repeated roots, and missing roots handled'
