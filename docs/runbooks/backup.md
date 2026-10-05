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

## Encrypted recovery files

Nix supplies `age` on the shared SSH/security layer; credentials are never Nix
inputs. Use a separately retained recovery passphrase, not the SSH key stored
inside the backup. [age's documentation](https://github.com/FiloSottile/age#passphrases)
describes interactive passphrase encryption. Enter it in a trusted terminal,
never in chat, an argument, a script, or an environment variable.

For an explicitly reviewed file set, stream the archive into `age --passphrase`
with `pipefail`, an owner-only local destination, and no plaintext staging file.
Use a new filename and refuse overwrites. Verify decryption and a restore
locally before copying **only the encrypted file** to the approved cloud
destination. Keep that recovery password accessible on another trusted device
and arrange an offline fallback; iCloud Passwords alone cannot recover a lost
Apple Account. An encrypted file synced to iCloud is still not an independent,
versioned backup of the whole computer.

Git bundles preserve committed history, not current working files. Code
snapshots need both, plus staged changes and tracked deletions. Ignore build
dependencies, but recover necessary ignored secrets separately. Preserve live
repositories and use an offline temporary restore to validate the snapshot.
