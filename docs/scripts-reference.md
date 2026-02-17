# Script Reference

Single source of truth for command-line flags in `/Users/rubennijhuis/dotfiles/scripts`.

## Global Convention

Most scripts support:

- `--help` to print usage
- `--no-color` to disable colored output

## Script Flags

- `scripts/doctor.sh`: `--help`, `--quick`, `--section <name>`, `--no-color`
- `scripts/doctor-notify.sh`: `--help`, `--no-color`, `--full`
- `scripts/migrate-developer-structure.sh`: `--help`, `--no-color`, `--dry-run`, `--complete`
- `scripts/restore-backup.sh`: `--help`, `--no-color`, `--dry-run`
- `scripts/sync-brew.sh`: `--help`, `--no-color`, `--dry-run`
- `scripts/validate-repos.sh`: `--help`, `--no-color`, `[path]`
- `scripts/update-repos.sh`: `--help`, `--no-color`, `--dry-run`, `[path]`
- `scripts/profile-shell.sh`: `--help`, `--no-color`, `--analyze`
- `scripts/sync-obsidian.sh`: `--help`, `--no-color`, `[path]`
- `scripts/setup-automation.sh`: `--help`, `--no-color`, `<backup|doctor>`
- `scripts/launchd-manager.sh`: `--help`, `--no-color`, `<command> [agent]`
- `scripts/startup-ai-services.sh`: no CLI flags (invoked by launchd at login)
- `install.sh`: `--help`, `--self-test-checkpoint`
- `scripts/update.sh`: `--help`, `--no-color`
- `scripts/stow-all.sh`: `--help`, `--no-color`
- `scripts/unstow-all.sh`: `--help`, `--no-color`
- `scripts/backup-dotfiles.sh`: `--help`, `--no-color`
- `scripts/format-all.sh`: `--help`, `--no-color`
- `scripts/brew-audit.sh`: `--help`, `--no-color`
- `scripts/gpg-info.sh`: `--help`, `--no-color`
- `scripts/ssh-info.sh`: `--help`, `--no-color`
- `scripts/migrate-ssh-keys.sh`: `--help`, `--no-color`

## Validation Commands

```bash
make check-scripts
make test-scripts
make maint-check
make maint          # runs maint-check, then prompts for maint-sync
```

## Grouped Maintenance Targets

```bash
make maint-check       # lint + script tests
make maint-sync        # update + brew sync/audit + repo updates
make maint-automation  # setup backup + doctor automations
```
