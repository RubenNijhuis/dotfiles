# Runbook: Incident Recovery

## Installer/Bootstrap Failure

1. Inspect `~/.cache/dotfiles-install.log` and resolve the reported prerequisite
   or failure. For a complete rebuild, use the [new-Mac checklist](new-mac-recovery.md).
2. Re-run `./install.sh` to resume from its last successful checkpoint.
3. If needed, inspect `./install.sh --help`, then start from a known step:

```bash
./install.sh --from-step <step-number>
```

Editor/automation setup is step 8. If it fails, step 7 remains the last saved
checkpoint; plain `./install.sh` resumes, or `./install.sh --from-step 8`
explicitly reruns it. Resolve missing declared editor configuration/CLI or a
selected job's prerequisite first; the installer does not mark skipped required
setup as complete.

## Launchd Automation Failure

```bash
make doctor ARGS=--automation
make launchd-status
bash ops/automation/launchd-manager.sh restart <agent>
```

## Config Drift

```bash
make nix-check      # evaluate the declared configuration
make nix-build      # build without changing the machine
make nix-switch     # apply the macOS configuration
make doctor         # verify
```

ChezMoi is retired. Restore private overrides locally rather than rendering
secrets into Nix; consult the [ownership matrix](../nix-ownership-matrix.md).

## Local override restore

Preview a retained local snapshot first:

```bash
bash ops/restore-backup.sh --dry-run
```

Then restore only reviewed destinations; the command asks for confirmation:

```bash
bash ops/restore-backup.sh
```

This restores local overrides, not a Nix system generation, private keyring or
personal files. Nix-owned symlinks are rejected rather than overwritten.
See the [backup runbook](backup.md) for its scope. An installed local snapshot
is not an independent disk-loss backup; that work remains deferred.
