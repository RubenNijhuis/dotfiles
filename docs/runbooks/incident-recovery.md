# Runbook: Incident Recovery

## Installer/Bootstrap Failure

1. Inspect `~/.cache/dotfiles-install.log`.
2. Re-run installer (`./install.sh`) to resume from checkpoint.
3. If needed, force restart from a known step:

```bash
./install.sh --from-step <1-7>

# The temporary pre-Nix bootstrap still has nine steps.
./install.sh --legacy --from-step <1-9>
```

## Launchd Automation Failure

```bash
make doctor --automation
~/dotfiles/ops/automation/launchd-manager.sh status
~/dotfiles/ops/automation/launchd-manager.sh restart <agent>
```

## Config Drift

```bash
make nix-check      # evaluate the declared configuration
make nix-build      # build without changing the machine
make nix-switch     # apply the macOS configuration
make doctor         # verify
```

Use `chezmoi diff` and `chezmoi apply` only when the affected path is still
marked transition-owned in the [Nix ownership matrix](../nix-ownership-matrix.md).

## Last-Resort Restore

```bash
bash ops/restore-backup.sh
```
