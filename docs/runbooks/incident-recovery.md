# Runbook: Incident Recovery

## Installer/Bootstrap Failure

1. Inspect `~/.cache/dotfiles-install.log`.
2. Re-run installer (`./install.sh`) to resume from checkpoint.
3. If needed, force restart from a known step:

```bash
./install.sh --from-step <1-10>
```

## Launchd Automation Failure

```bash
make ops-status
~/dotfiles/scripts/launchd-manager.sh status
~/dotfiles/scripts/launchd-manager.sh restart <agent>
```

## Config Drift or Broken Links

```bash
make stow-report
make unstow
make stow
make doctor
```

## Last-Resort Restore

```bash
make restore
```
