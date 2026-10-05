# Runbook: Incident Recovery

## Installer/Bootstrap Failure

1. Inspect `~/.cache/dotfiles-install.log`.
2. Re-run installer (`./install.sh`) to resume from checkpoint.
3. If needed, force restart from a known step:

```bash
./install.sh --from-step <1-7>
```

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

## Last-Resort Restore

```bash
bash ops/restore-backup.sh
```
