# Runbook: New Mac Recovery

Nix restores software and supported settings. It does not restore personal
data, secrets, accounts, or device trust.

## Everyday loss protection

No reset is planned. The current priorities are uploaded durable files in the
existing iCloud Files tree and remotely saved Git configuration. `make doctor`
reports local-only dotfiles commits and uncommitted entries using cached remote
refs; it does not contact GitHub, push, move files, or verify iCloud uploads.
An active Nix generation is not evidence its source is saved remotely.

Passwords already synced through Apple Passwords are not a local-only gap.
Private SSH/GPG keys, deployment state, and app-owned project data need their
own recovery method; never upload plaintext credentials with ordinary files.
Keep repositories and dependencies outside iCloud and use supported app
exports for creative projects. Independent backup work remains deferred.

### Verified on this Mac (2026-10-05)

- Photos has iCloud Photos enabled, uses Optimise Mac Storage, and reported a
  recent successful sync. This is not a full offline copy or an independent backup.
- Thunderbird's local mail stores contain only empty Outbox/Trash files. Its
  local calendar databases and Personal Address Books were empty in all three
  profiles. The active Collected Addresses database has pending WAL data and
  remains unverified; server-side retention is not established by these checks.
- A supported Resolve project export was created and its ZIP integrity verified
  under `~/Private/System Migration/Resolve Exports/2026-10-05/`. Source media
  and a successful import still need separate verification; `.drp` excludes media.
- Five selected personal-code snapshots were saved under
  `~/Private/System Migration/Code Recovery/2026-10-05/`. Offline restores passed
  Git integrity, working-file comparisons, and staged/unstaged status checks.
  They include Git history and tracked/non-ignored untracked files, not ignored
  dependencies or `.env` files. These copies are still on this disk only.
- Steam has eight files in its local `remote` folders (about 94 KB). Those names
  do not prove Steam Cloud upload; saves elsewhere remain outside this inventory.

Do not infer remote protection from these local tests. Other repositories,
ignored secrets, Photo Booth media, app-local contacts/calendars, and private
archives remain distinct recovery targets. Never publish WIP or upload archived
employer data simply because a repository has no upstream.

## Before erasing the old Mac

1. Confirm an **encrypted off-device backup** of `~/Files` and `~/Private`.
   `make backup` is only a local plaintext rollback snapshot; it is not
   sufficient for a reset, loss, or disk failure.
2. Verify a restore into a temporary location. Keep recovery material for the
   password vault, Apple Account, and other critical services separately.
3. Export any durable Apple Shortcuts as `.shortcut` files. Do not copy
   application databases, browser profiles, or mail stores wholesale.
4. Ensure the dotfiles repository is pushed and clean.

## Rebuild

1. Update macOS, install Xcode Command Line Tools, clone this repository to
   `~/Developer/personal/dotfiles`, then run `./install.sh`.
2. Run `make nix-build`, `make nix-switch`, and `make doctor`.
3. Reconnect the existing iCloud Drive/Obsidian/Files vault, enable **Keep
   Downloaded**, and recreate the `~/Files` symlink following the
   [guarded reconnect instructions](../file-sync-options.md#reconnect-on-another-mac).
   Restore `~/Private` separately from a verified encrypted backup. Do not
   restore a second Files tree over the live synced vault blindly.
4. Recreate device-bound state manually: Apple Account, FileVault, Touch ID,
   Wi-Fi, privacy permissions, and required Keychain entries.
5. Sign into application-supported sync deliberately: Zen/Twilight, Signal,
   Thunderbird, Obsidian, and the chosen calendar service. Never copy their
   opaque databases into the repository.
6. Run `make vscode-setup`, `make hooks`, and `make automation-setup` when
   those capabilities are wanted. Neovim's plugins, native completion library,
   and selected parsers now arrive with Nix; no `:Lazy sync` is required.

## Verify

- `make nix-check-all`, `make bootstrap-verify`, and `make doctor ARGS=--full` pass.
- Thunderbird opens the signed-in account; Zen opens the intended synced
  profile; Obsidian opens `~/Files`.
- Calendar notifications work on Apple devices and the operational calendar is
  not duplicated across providers.
- Restore one non-critical document and one private record from backup before
  treating the new Mac as recoverable.

## Remaining reproducibility gaps

Reviewed on 2026-10-05; these are not covered by a successful Nix build alone:

| Component | What still needs attention |
| --- | --- |
| Ruby/Mise | Global Mise activation is retired; no Ruby manifest was found in the active personal/work scan. Ruby 4.0.5 was moved recoverably to Trash. Older Node/Yarn installs remain for project compatibility, not baseline restore requirements. A future Ruby project needs its own devShell. |
| Private shell override | Restore `~/.config/shell/local.sh` locally with mode 0600 only when still needed. It is optionally sourced, never templated or stored in Nix. The archived ChezMoi config may contain old secret values and belongs in encrypted backup, not Git. |
| Spotify theming | Nix restores the CLI and reusable theme only. Spotify itself, `config-xpui.ini`, backup state, and account sign-in remain app-owned; do not import an old tracked config with stale absolute paths or backup versions. |
| Neovim | Nix restores the binary, configuration, plugins, native completion, and selected parsers. Bash/Lua servers and formatters are in the developer profile. Other language servers/SDKs need project environments or explicit manual Mason installs. Update through Nix, not `:Lazy sync`/`:TSUpdate`. The old Lazy checkouts and Mason Lua server were moved recoverably to Trash; remaining local Mason metadata/lockfiles are not restore requirements. Copilot authentication is not covered by the isolated smoke test. |
| VS Code | Settings are Nix-owned. All 22 declared extension IDs are installed on this Mac; versions remain marketplace-managed. `make vscode-setup ARGS=--check` detects missing IDs, and unlisted extensions remain untouched. |
| Raycast | The Script Commands folder is registered and enabled on this Mac. New Macs still require one manual directory registration; private Raycast data is not version controlled. |
| Git signing | The configuration expects `~/.ssh/id_ed25519_personal.pub` and its matching private key or agent. Restore/provision and test signing separately; Nix does not supply keys. macOS Keychain credential handling is Mac-only. |
| Active project environments | The website now has its own flake/lock: Mac runtime verified as Node 24.21.0 and pnpm 12.8.1; Linux shells evaluated only. Nix pins Node and the pnpm launcher; the exact project pnpm selection remains application-managed. The shared Node 22/Yarn 1.22.22 compatibility shell also passed on this Mac, but older projects have not yet adopted their own shells. |
| Calendar | Apple Calendar is the Mac default, with the iCloud Personal calendar selected explicitly for new events. Verified defaults are 15 minutes before timed events and the day before at 09:00 for all-day events; existing events were not edited. The “only this computer” restriction is off. Re-select the calendar after restoring an account; other-device notification delivery still needs testing. |
| Private records | Private personal documents intentionally stay in purpose-based folders in the iCloud-backed Files tree. Restore credentials and technical migration material separately; do not upload the whole local Private folder. Independent encrypted recovery remains a prerequisite for reset. |

`make nix-check-all` now evaluates actual host activation derivations on every
declared platform without trying to build Linux software on the Mac.

To test a built editor without personal state, run
`bash tests/test-neovim.sh ~/.config/nvim --smoke` after activation. It uses a
temporary profile, blocks unexpected subprocesses, excludes AI clients, and
tests parser loading, native completion, and Lua LSP startup. It requires the
developer profile's language tools; it is not an account/sign-in test.
The same test is a native Nix check (`checks.<system>.neovim`) and gates
`make update` verification, so plugin compatibility is checked before activation.
