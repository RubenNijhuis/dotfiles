# Runbook: Incident Recovery

## Installer/Bootstrap Failure

1. Inspect `~/.cache/dotfiles-install.log`.
2. Re-run installer (`./install.sh`) to resume from checkpoint.
3. If needed, force restart from a known step:

```bash
./install.sh --from-step <1-9>
```

## Launchd Automation Failure

```bash
make doctor --automation
~/dotfiles/ops/automation/launchd-manager.sh status
~/dotfiles/ops/automation/launchd-manager.sh restart <agent>
```

## Config Drift

```bash
chezmoi diff        # preview pending changes
chezmoi apply       # materialize source state into $HOME
make doctor         # verify
```

## Last-Resort Restore

```bash
bash ops/restore-backup.sh
```
