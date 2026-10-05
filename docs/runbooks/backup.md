# Runbook: Backups

`make backup` creates **local plaintext rollback snapshots**, not a complete
computer backup. It includes repository local overrides, regular SSH files
(including public keys), `shell/local.sh`, and GPG `common.conf`. It does **not**
include GPG private keys, `~/Files`, `~/Private`, Keychain, account recovery,
browser/app state, or an off-device copy. Do not erase a Mac on this basis.

## Commands

```bash
make backup
bash ops/restore-backup.sh --dry-run
```

## Validation

- Snapshots and their root are owner-only (directories 0700, files 0600).
- Nested paths are retained; snapshots never follow source symlinks.
- Each run has a unique directory. Old snapshots are **not automatically
  deleted**; review exact targets before pruning.
- Status follows the completed `latest` snapshot, not a folder left behind by
  a failed run. Enumeration/copy failures do not advance that pointer.
- If the optional `com.user.dotfiles-backup` agent is installed, check its logs
  under `~/.local/log/dotfiles-backup.*`. It offers rollback, not disaster recovery.

## Recovery

```bash
bash ops/restore-backup.sh
```

Use latest successful backup directory shown in status output.
Restore requires confirmation and rejects symlinked destinations, including
Nix-owned configuration links. Preview first. Legacy `.tar.gz` snapshots must
be reviewed and unpacked separately; even a preview never extracts them.

For reset/loss recovery, follow [New Mac Recovery](new-mac-recovery.md): an
encrypted off-device backup and a verified restore remain necessary.
