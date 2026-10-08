"""Exercise the metadata-only audit against disposable fixtures, never real data."""

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location(
    "storage_audit", Path(__file__).resolve().parents[1] / "ops/storage-audit.py"
)
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class StorageAuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)

    def measure(self, path):
        return audit.measure("fixture", path, 1, self.home, "/usr/bin/du")

    def test_skips_symlinks_cloud_and_missing_paths(self):
        cloud = self.home / "Library/Mobile Documents/fixture"
        cloud.mkdir(parents=True)
        alias = self.home / "alias"
        alias.symlink_to(cloud)
        with patch.object(audit.subprocess, "run") as run:
            self.assertEqual(self.measure(alias)["status"], "skipped_symlink")
            self.assertEqual(self.measure(cloud)["status"], "skipped_cloud")
            self.assertEqual(self.measure(self.home / "absent")["status"], "missing")
            run.assert_not_called()

    def test_sparse_file_counts_allocated_not_logical_size(self):
        sparse = self.home / "sparse"
        with sparse.open("wb") as handle:
            handle.truncate(100 * 1024 * 1024)
        row = self.measure(sparse)
        self.assertEqual(row["allocated_bytes"], sparse.stat().st_blocks * 512)
        self.assertEqual(row["measurement"], "stat_blocks")

    def test_directory_command_is_metadata_only(self):
        result = subprocess.CompletedProcess([], 0, "12\tfixture\n", "")
        with patch.object(audit.subprocess, "run", return_value=result) as run:
            row = self.measure(self.home)
            self.assertEqual(row["allocated_bytes"], 12 * 1024)
            self.assertEqual(run.call_args.args[0], ["/usr/bin/du", "-skPx", str(self.home)])
            self.assertEqual(run.call_args.kwargs["timeout"], 1)

    def test_failure_and_timeout_are_not_zero_size(self):
        with patch.object(audit.subprocess, "run", side_effect=subprocess.TimeoutExpired("du", 1)):
            row = self.measure(self.home)
            self.assertEqual(row["status"], "timeout")
            self.assertIsNone(row["allocated_bytes"])
        result = subprocess.CompletedProcess([], 1, "", "Permission denied: private-name")
        with patch.object(audit.subprocess, "run", return_value=result):
            row = self.measure(self.home)
            self.assertEqual(row["status"], "denied")
            self.assertNotIn("private-name", str(row))
        result = subprocess.CompletedProcess([], 1, "5\tfixture\n", "Permission denied")
        with patch.object(audit.subprocess, "run", return_value=result):
            self.assertEqual(self.measure(self.home)["status"], "partial")

    def test_comparison_requires_complete_measurements(self):
        before = {"rows": [{"path": "/fixture", "status": "ok", "allocated_bytes": 30}]}
        rows = [{"path": "/fixture", "status": "partial", "allocated_bytes": 20}]
        audit.compare(rows, before)
        self.assertNotIn("change_bytes", rows[0])
        rows[0]["status"] = "ok"
        audit.compare(rows, before)
        self.assertEqual(rows[0]["change_bytes"], -10)

    def test_rejects_unbounded_timeouts(self):
        for value in ["0", "-1", "nan", "inf"]:
            with self.assertRaises(audit.argparse.ArgumentTypeError):
                audit.positive_timeout(value)


if __name__ == "__main__":
    unittest.main()
