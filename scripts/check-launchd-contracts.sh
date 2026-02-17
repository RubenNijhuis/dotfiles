#!/usr/bin/env bash
# Validate LaunchD template contracts for managed agents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color]

Validate templates/launchd/*.plist against repository launchd contract.
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-color)
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  print_header "LaunchD Template Contract Check"

  python3 - "$DOTFILES/templates/launchd" <<'PY'
import os
import plistlib
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
files = sorted(root.glob("com.user.*.plist"))
if not files:
    print("No launchd templates found")
    sys.exit(1)

errors = []


def walk_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for v in value.values():
            yield from walk_strings(v)
    elif isinstance(value, list):
        for v in value:
            yield from walk_strings(v)

for file in files:
    expected_label = file.stem
    expected_name = re.sub(r"^com\.user\.", "", file.stem)

    try:
        with file.open("rb") as fh:
            data = plistlib.load(fh)
    except Exception as exc:
        errors.append(f"{file.name}: invalid plist ({exc})")
        continue

    label = data.get("Label")
    if label != expected_label:
        errors.append(f"{file.name}: Label must be '{expected_label}' (got '{label}')")

    args = data.get("ProgramArguments")
    if not isinstance(args, list) or not args:
        errors.append(f"{file.name}: ProgramArguments must be a non-empty array")
    else:
        first = str(args[0])
        if "__DOTFILES__/scripts/" not in first:
            errors.append(
                f"{file.name}: ProgramArguments[0] must reference '__DOTFILES__/scripts/'"
            )

    out_path = data.get("StandardOutPath")
    err_path = data.get("StandardErrorPath")
    for key, value in (("StandardOutPath", out_path), ("StandardErrorPath", err_path)):
        if not isinstance(value, str):
            errors.append(f"{file.name}: {key} must be a string")
            continue
        if not value.startswith("__HOME__/.local/log/"):
            errors.append(f"{file.name}: {key} must live under '__HOME__/.local/log/'")
        if not value.endswith(".log"):
            errors.append(f"{file.name}: {key} must end with '.log'")

    if not any(k in data for k in ("RunAtLoad", "StartCalendarInterval", "StartInterval")):
        errors.append(
            f"{file.name}: must define scheduling via RunAtLoad, StartCalendarInterval, or StartInterval"
        )

    for s in walk_strings(data):
        if "/Users/" in s:
            errors.append(f"{file.name}: contains hardcoded user path '{s}'")

    if isinstance(out_path, str) and expected_name not in out_path:
        # Non-fatal naming recommendation enforced as strict contract for consistency.
        errors.append(
            f"{file.name}: StandardOutPath should include agent name '{expected_name}'"
        )

if errors:
    print("Launchd template contract violations:")
    for err in errors:
        print(f"- {err}")
    sys.exit(1)

print(f"Validated {len(files)} launchd templates")
PY

  print_success "LaunchD contracts look good"
}

main "$@"
