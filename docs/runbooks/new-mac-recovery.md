# Runbook: New Mac Recovery

Nix restores software and supported settings, not personal files, secrets,
accounts, licences, or device trust. No erase is planned; independent backup
work and this Mac's OS update/restart remain deferred.

## What restores from where

| Owner | Restore source and limits |
| --- | --- |
| Nix / Git | This repository and `flake.lock`: selected packages, supported macOS defaults, shell/editor/Git configuration, Neovim plugins/parsers, and declared login tasks. Nix is the first package owner; use only documented native/Homebrew exceptions. |
| iCloud | The existing Obsidian `Files` vault, editable vault preferences, durable personal documents, and Apple-supported sync such as Passwords and Photos when enabled. `~/Files` is the stable symlink, not a second vault. Presence on this Mac does not prove upload completion; sync is not an independent backup. |
| GitHub | Retained source-code repositories, including branches and unfinished work deliberately saved there. Local changes, stashes, ignored files and absent remotes are not automatically covered. Dependencies and builds stay outside iCloud. |
| User / application | Sign-ins, permissions, licences, private keys, local secrets, app exports, game saves and creative-project state. Provision or restore these deliberately through the owning application; do not copy their databases into Git or the Nix store. |
| Disposable | Rebuildable caches, dependency trees, old migration copies and ordinary application state explicitly accepted as replaceable. This is not permission to delete anything further. |

Ordinary private personal records belong in purpose-based folders in the
iCloud-backed Files tree. Local `~/Private` remains for credentials, technical
secrets and any material deliberately kept local; it is not automatically
synced or restored by Apple Passwords. Do not upload that entire folder.

## Current baseline

Checked on 2026-10-13: this Mac uses generation **61** and the repository's
GitHub remote uses **SSH**. Earlier approved migration copies and generations
1–54 were retired; do not treat old Code Recovery, browser, database or
configuration migration folders as restore sources. Mave archives remain
untouched. Use Git history to recover older configuration source, not an
assumed installed rollback generation.

`make doctor` reports local-only dotfiles commits and uncommitted entries
against cached remote refs. It does not contact GitHub, push work, or verify
iCloud uploads. Neither a clean working tree nor an active Nix generation
proves all retained work is remotely saved.

## Rebuild on another Mac

1. Use Apple Silicon and local username `rubennijhuis`, or adapt the flake and
   bootstrap host checks first. Install Xcode Command Line Tools and select a
   supported macOS release; schedule any OS update/restart separately.
2. Sign into the same Apple Account and enable iCloud Drive. Wait for the
   actual Obsidian app container and existing Files vault, enable **Keep
   Downloaded**, then follow the [guarded stable-path reconnect](../file-sync-options.md#restore-the-stable-mac-path).
   Do this before writing notes or screenshots to `~/Files`. Never force an
   existing path or merge two vaults; the installer does not restore iCloud.
3. Clone and apply the locked configuration:

   ```sh
   git clone https://github.com/RubenNijhuis/dotfiles.git ~/Developer/personal/dotfiles
   cd ~/Developer/personal/dotfiles
   ./install.sh
   ```

   The initial HTTPS clone needs no provisioned SSH identity. The installer
   installs/verifies Lix/Nix, checks and builds the locked Mac configuration,
   applies it, then installs the selected documented Homebrew exceptions.
   It creates the Developer structure and enables repository hooks. A second
   `make nix-switch` is unnecessary unless configuration changed. Re-run the
   installer to resume a failed checkpoint, then open a new terminal.
4. Restore/provision private SSH and GPG keys securely, never through Nix or
   ordinary plaintext iCloud files. Git's public signing identifier is in
   `nix/lib/identity.nix`; private keys are not. `make gpg-setup` checks the
   selected key's availability, not a real signature or GitHub registration.
   Restore the existing identity where possible; `make ssh-setup` generates a
   key only when absent and still requires deliberate GitHub registration.
   After SSH is working, change this clone's remote to
   `git@github.com:RubenNijhuis/dotfiles.git`.
5. Recreate device trust: FileVault/recovery access, Touch ID, Wi-Fi, required
   Keychain entries and privacy permissions. Review the
   [permission checklist](../macos-settings-migration.md#reproducible-permission-policy);
   Nix cannot grant these approvals or restore biometrics.
6. Open the preferred apps and sign in deliberately: Zen/Twilight,
   Thunderbird, Signal, Obsidian and Apple Calendar. Follow the
   [application catalog](../application-catalog.md) for native exceptions,
   licences and app-owned state. Keep a single intended profile per app.
7. Run `make vscode-setup` for the declared marketplace extensions and
   `make automation-setup` for only the active profile's selected jobs.
   Register Raycast's Script Commands directory once. Import any retained
   personal Shortcuts through Shortcuts itself. These steps are not performed
   by the main installer; avoid blanket installation of every launchd job.

## Remaining manual recovery boundaries

- **Editors:** VS Code settings/extension IDs are declared, but marketplace
  extension versions remain app-managed. Neovim plugins and selected parsers
  arrive with Nix; do not run `:Lazy sync` or `:TSUpdate` to replace them.
  Project-specific SDKs/language tools belong in project environments.
- **Private overrides and keys:** restore `~/.config/shell/local.sh` only if
  needed, with owner-only permissions (0600). Git signing and SSH authentication
  are separate: restore keys, confirm GitHub's public-key/email registration,
  and verify both without disabling signing. Keychain passphrase availability
  is device-specific; GPG caching remains time-limited.
- **Writable app state:** Spotify's runtime/theming backup state, Raycast and
  OneMenu preferences, browser profiles, mail/contacts, creative libraries,
  licences and game saves are not restored by installing their applications.
  Use supported exports/sync where retained work matters; do not assume cloud
  coverage merely because an application offers it.
- **Calendar:** Apple Calendar is the default on Apple devices. Re-select the
  intended iCloud calendar for new events and review notification permissions;
  installing a client does not reconnect an account or migrate appointments.
- **Local machine choices:** `local/profile.env` selects exception packages
  and operational automation, not Nix host imports. Preserve any intentional
  non-secret local choices separately or recreate them explicitly.

## Check after recovery

Start with `make doctor`, `make app-audit ARGS=--check`,
`make vscode-setup ARGS=--check` and `make doctor ARGS=--automation`.
Confirm that the intended mail/browser profiles open and Obsidian opens
`~/Files`; verify the same harmless note on another device and offline on this
Mac. Check calendar notifications without modifying existing appointments.
Verify SSH authentication and a disposable signed commit before relying on
GitHub recovery. Do not push a test commit to a real project.

For changed bootstrap/configuration, use `make nix-check-all` and
`make bootstrap-verify`: they evaluate declared platforms and isolated
bootstrap contracts, not a real clean-Mac installation. A successful Mac build
does not establish Linux runtime behaviour, sign-ins, sync or data recovery.

Before any future erase, confirm actual remote file/code coverage and recovery
access, and verify a restore from an independent encrypted off-device backup.
That backup work remains deferred, not completed. `make backup` creates only a
local plaintext dotfiles rollback snapshot and is insufficient for disk loss.
Never use retired migration folders as evidence of protection.
