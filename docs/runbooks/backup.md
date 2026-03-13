# Runbook: Backups

## Commands

```bash
make backup
make automation-setup   # sets up backup + doctor + repo-update automations
make ops-status         # check all automation statuses
```

## Validation

- Ensure latest backup exists in `~/.dotfiles-backup/`.
- Confirm `com.user.dotfiles-backup` is loaded.
- Check logs under `~/.local/log/dotfiles-backup.*`.

## Recovery

```bash
bash scripts/backup/restore-backup.sh
```

Use latest successful backup directory shown in status output.
