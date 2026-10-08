#!/usr/bin/env python3
"""Report allocated storage metadata without opening file contents or changing data."""

import argparse
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys


SCHEMA_VERSION = 1
SF_DATALESS = 0x40000000
NOTES = [
    "Rows can be nested or share APFS extents; their sizes are not additive.",
    "Allocation is not a deletion recommendation or an estimate of reclaimable space.",
    "Only aggregate metadata is read; no contents, hashes, downloads, or cleanup commands.",
]


def default_targets(home):
    group = home / "Library/Group Containers"
    whatsapp = group / "group.net.whatsapp.WhatsApp.shared"
    return [
        ("Spotify offline storage", home / "Library/Application Support/Spotify/PersistentCache"),
        ("Steam installed data", home / "Library/Application Support/Steam/steamapps"),
        ("CrossOver bottles", home / "Library/Application Support/CrossOver/Bottles"),
        ("OrbStack data image", group / "HUAQ24HBR6.dev.orbstack/data/data.img.raw"),
        ("OrbStack swap image", group / "HUAQ24HBR6.dev.orbstack/data/swap.img"),
        ("WhatsApp message media", whatsapp / "Message/Media"),
        ("WhatsApp media", whatsapp / "Media"),
        ("Nix store", Path("/nix/store")),
        ("System simulators", Path("/Library/Developer/CoreSimulator")),
        ("User simulators", home / "Library/Developer/CoreSimulator"),
        ("pnpm alternate store", home / ".local/share/pnpm/store"),
        ("pnpm macOS store", home / "Library/pnpm/store"),
        ("npm cache", home / ".npm/_cacache"),
        ("pnpm download cache", home / ".cache/pnpm"),
        ("uv cache", home / ".cache/uv"),
        ("Homebrew downloads", home / "Library/Caches/Homebrew/downloads"),
        ("Zen cache", home / "Library/Caches/zen"),
        ("Developer total", home / "Developer"),
        ("Temporary files total", Path("/private/tmp")),
    ]


def under(path, root):
    return path == root or root in path.parents


def measure(label, path, timeout, home, du):
    path = Path(os.path.abspath(os.path.expanduser(str(path))))
    row = {"label": label, "path": str(path), "status": "ok", "allocated_bytes": None}
    try:
        info = path.lstat()
    except FileNotFoundError:
        row["status"] = "missing"
        return row
    except PermissionError:
        row["status"] = "denied"
        return row
    except OSError:
        row["status"] = "unavailable"
        return row

    # Do not follow explicit symlinks or traverse existing cloud providers.
    if stat.S_ISLNK(info.st_mode):
        row["status"] = "skipped_symlink"
        return row
    try:
        resolved = path.resolve()
        cloud_roots = [(home / folder).resolve() for folder in [
            "Library/Mobile Documents", "Library/CloudStorage"
        ]]
    except (OSError, RuntimeError):
        row["status"] = "unavailable"
        return row
    if any(under(resolved, root) for root in cloud_roots):
        row["status"] = "skipped_cloud"
        return row
    if getattr(info, "st_flags", 0) & SF_DATALESS:
        row["status"] = "skipped_dataless"
        return row
    if stat.S_ISREG(info.st_mode):
        row.update(allocated_bytes=info.st_blocks * 512, measurement="stat_blocks")
        return row
    if not stat.S_ISDIR(info.st_mode):
        row["status"] = "unsupported_type"
        return row
    if not du:
        row["status"] = "du_unavailable"
        return row

    try:
        # -P skips symlinks; -x stays on this filesystem, avoiding mounted runtimes.
        # du counts hardlinks once per invocation.
        result = subprocess.run(
            [du, "-skPx", str(path)], capture_output=True, text=True, errors="replace",
            timeout=timeout, check=False, env={**os.environ, "LC_ALL": "C"},
        )
    except subprocess.TimeoutExpired:
        row["status"] = "timeout"
        return row
    except OSError:
        row["status"] = "unavailable"
        return row

    # Never print du's diagnostics: they may contain private descendant names.
    summary = result.stdout.splitlines()
    try:
        kib = int(summary[-1].split("\t", 1)[0]) if summary else None
    except (ValueError, IndexError):
        kib = None
    if kib is not None:
        row.update(allocated_bytes=kib * 1024, measurement="du_allocated_kib")
    if result.returncode != 0:
        denied = "Permission denied" in result.stderr or "Operation not permitted" in result.stderr
        row["status"] = "partial" if kib is not None else ("denied" if denied else "incomplete")
    elif kib is None:
        row["status"] = "incomplete"
    return row


def human_size(value):
    if value is None:
        return "—"
    for suffix in ["B", "KiB", "MiB", "GiB", "TiB"]:
        if abs(value) < 1024 or suffix == "TiB":
            return f"{value:.2f} {suffix}"
        value /= 1024


def disk_capacity():
    path = "/System/Volumes/Data"
    result = {"path": path, "status": "ok", "total_bytes": None, "used_bytes": None, "free_bytes": None}
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        result["status"] = "unavailable"
    else:
        result.update(total_bytes=usage.total, used_bytes=usage.used, free_bytes=usage.free)
    return result


def compare(rows, previous):
    before = {r["path"]: r for r in previous["rows"]}
    for row in rows:
        old = before.get(row["path"])
        if old and old.get("status") == row["status"] == "ok":
            amount = old.get("allocated_bytes")
            if isinstance(amount, int) and row["allocated_bytes"] is not None:
                row["change_bytes"] = row["allocated_bytes"] - amount


def positive_timeout(value):
    number = float(value)
    if not math.isfinite(number) or number <= 0:
        raise argparse.ArgumentTypeError("timeout must be finite and greater than zero")
    return number


def print_row(row):
    delta = row.get("change_bytes")
    change = ("+" if delta > 0 else "") + human_size(delta) if delta is not None else "—"
    print(f"{row['label']:28} {human_size(row['allocated_bytes']):>14} {row['status']:20} {change:>14}", flush=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="print JSON instead of the table")
    parser.add_argument("--timeout", type=positive_timeout, default=30.0,
                        help="maximum seconds for each directory (default: 30)")
    parser.add_argument("--path", action="append", metavar="PATH",
                        help="inspect only these explicit paths; repeatable")
    parser.add_argument("--compare", type=Path, metavar="JSON",
                        help="compare complete rows with a previous JSON report")
    args = parser.parse_args(argv)
    if sys.platform != "darwin" and not args.path:
        parser.error("default app paths are for macOS; use --path for explicit fixtures")
    previous = None
    if args.compare:
        try:
            previous = json.loads(args.compare.read_text())
            if previous.get("schema_version") != SCHEMA_VERSION or not isinstance(previous["rows"], list):
                raise ValueError
            if any(not isinstance(row, dict) or not isinstance(row.get("path"), str) for row in previous["rows"]):
                raise ValueError
        except (OSError, UnicodeError, ValueError, KeyError, AttributeError, TypeError):
            parser.error("comparison input must be a readable storage-audit JSON report")

    home = Path.home()
    disk = disk_capacity()
    targets = [(f"Custom path {i + 1}", Path(p)) for i, p in enumerate(args.path)] if args.path else default_targets(home)
    if not args.json:
        if disk["status"] == "ok":
            print(f"Disk available: {human_size(disk['free_bytes'])} of {human_size(disk['total_bytes'])} total", flush=True)
        else:
            print("Disk capacity: unavailable", flush=True)
        print(f"{'Target':28} {'Allocated':>14} {'Status':20} {'Change':>14}", flush=True)
    rows = []
    du = "/usr/bin/du" if sys.platform == "darwin" else shutil.which("du")
    for label, path in targets:
        row = measure(label, path, args.timeout, home, du)
        if previous is not None:
            compare([row], previous)
        rows.append(row)
        if not args.json:
            print_row(row)
    report = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "platform": sys.platform,
        "disk": disk,
        "timeout_seconds": args.timeout,
        "notes": NOTES,
        "rows": rows,
    }
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print()
        for note in NOTES:
            print(note)
        print("Partial rows exclude unreadable items; missing or skipped rows are not zero-size results.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
