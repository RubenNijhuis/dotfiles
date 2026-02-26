# Runbook: Backups

## Commands

```bash
make backup
make backup-setup
make backup-status
make backup-verify
```

## Validation

- Ensure latest backup exists in `~/.dotfiles-backup/`.
- Confirm `com.user.dotfiles-backup` is loaded.
- Check logs under `~/.local/log/dotfiles-backup.*`.

## Recovery

```bash
make restore
```

Use latest successful backup directory shown in status output.
