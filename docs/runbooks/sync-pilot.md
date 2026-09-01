# Runbook: cross-device file sync pilot

This runbook deliberately starts small. It does not synchronize the home
directory, application databases, credentials, Photos libraries, or `Private`.

## Scope

Use exactly this first folder on each trusted device:

```text
~/Files/90 Shared/Sync Pilot
```

The Nix `sync` profile supplies Syncthing and Restic on the Mac and Linux
desktop. It does not start Syncthing, pair a device, create a shared folder, or
configure a backup destination. Those are personal trust and recovery choices,
not declarative machine state. Windows uses the native Syncthing application
against `C:\Users\<you>\Files` when that device is ready.

## Before pairing

1. Run `make files-init` on each device.
2. Confirm the pilot folder contains only disposable test files.
3. In Syncthing, enable staggered file versioning for this folder before adding
   a second device.
4. Do not share `~/Private`, `~/Developer`, browser data, mail stores, app
   support folders, caches, or password-vault exports.

## Test sequence

1. Create `2026-09-01 sync-pilot.md` on the Mac and confirm it arrives on the
   second device.
2. Take both devices offline, edit the same line differently, reconnect them,
   and confirm Syncthing preserves a conflict copy rather than discarding work.
3. Delete the file on one device and restore it from Syncthing version history.
4. Record the result and only then add one clearly owned folder at a time.

## Backup is separate

Syncthing availability is not a backup. Before relying on the shared folders,
choose an encrypted Restic repository, set a retention policy, back up both
`~/Files` and `~/Private`, and restore one test file into a temporary location.
Do not put a repository password, destination URL, device ID, or recovery key
in this repository.
