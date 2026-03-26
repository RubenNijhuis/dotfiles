#!/usr/bin/env python3
"""Validate LaunchD plist templates against repository launchd contract.

Usage: python3 validate_launchd.py <templates_dir>

Checks each com.user.*.plist for:
- Label matches filename
- ProgramArguments references __DOTFILES__/
- StandardOutPath/StandardErrorPath under __HOME__/.local/log/
- Deterministic scheduling (RunAtLoad, StartCalendarInterval, or StartInterval)
- No hardcoded user paths
- Log filenames include agent name
"""
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
        if not first.startswith("__DOTFILES__/"):
            errors.append(
                f"{file.name}: ProgramArguments[0] must reference '__DOTFILES__/'"
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
        errors.append(
            f"{file.name}: StandardOutPath should include agent name '{expected_name}'"
        )

if errors:
    print("Launchd template contract violations:")
    for err in errors:
        print(f"- {err}")
    sys.exit(1)

print(f"Validated {len(files)} launchd templates")
