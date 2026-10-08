# macOS settings migration

Nix should own durable, repeatable preferences—not every byte of the user
profile. The first declarative macOS settings module is
`nix/darwin/defaults.nix`.

## Nix-owned settings

- Finder, Dock, keyboard-repeat, text-substitution, trackpad, appearance,
  screenshot, and screen-lock preferences supported by nix-darwin.
- Touch ID for `sudo`.
- Application firewall and stealth mode enabled. Existing application
  exceptions are not reset, and this does not enable remote-access services.
- New Finder windows open `~/Files`. Sidebar favourites remain Finder-owned.
- Remote Login (SSH server) is disabled. Outbound SSH remains available.
- Screen Sharing and SSH launchd jobs are disabled and unloaded at Nix
  activation; Apple's system plists stay untouched. Re-enabling remote access
  requires a deliberate policy change, not an unattended exception.
- Home Manager alone initializes Zsh completion and the Starship prompt;
  nix-darwin's duplicate global initialization is disabled.
- Home Manager shell, terminal, Git, editor, command-line programs, and other
  user configuration.
- The narrow macOS package catalog once the Nix activation is stable.

## Saved outside Nix, by design

| Category | Owner | Reason |
| --- | --- | --- |
| Apple ID, iCloud data, App Store purchases | macOS / account provider | Account state and private data cannot safely live in the Nix store. |
| Keychain, passkeys, passwords, recovery material | Keychain or chosen password vault | Secrets must never be committed or placed in a world-readable Nix store. |
| Privacy permissions, Screen Recording, Accessibility, TCC approvals | macOS | These are security decisions bound to a device/user and cannot be reliably pre-granted declaratively. |
| Wi-Fi, Bluetooth pairings, hardware calibration, Touch ID enrollment | macOS hardware settings | Device-specific and sometimes security-sensitive. |
| Application databases and caches | Each application | Sync/export the underlying user data, not opaque databases. |
| Shortcuts | Shortcuts app plus exported `.shortcut` files for chosen durable shortcuts | Shortcuts are an Apple-managed user database; export only the shortcuts worth preserving. |

## Transition rule

The supported preferences are owned by `nix/darwin/defaults.nix`. ChezMoi is
retired; applications and private local overrides must not compete with those
declarative macOS preferences.

## Future additions, reviewed one category at a time

1. Finder sidebar and Dock apps after selecting the lean everyday app core.
2. Keyboard modifier mappings and Control Center preferences if their
   hardware-specific constraints are understood.
3. Homebrew ownership through nix-darwin after the Homebrew catalog is
   reduced and observed.
4. Exported Shortcuts for durable manual workflows; use Shortcuts first for
   user-facing automation, and avoid hidden background file watchers.

## Privacy and manual capture

VS Code and GitLens telemetry are disabled in the shared editor settings.
AI assistance is a separate data-transmission decision; these preferences
do not disable Copilot or guarantee that every extension stops telemetry.

Review remote-login/screen-sharing switches and browser passkey-site access
on each Mac. TCC permissions and account Sync choices remain device/app-owned;
do not grant them through scripts or copy their databases into Git.

### Reproducible permission policy

`nix/profiles/macos-apps.nix` saves the reviewed manual permission checklist as
`~/.config/dotfiles/macos-permissions.txt` on each configured Mac. Nix owns the
desired policy and restore instructions, **not** the live privacy grants. Review
app identities before approving; an installed checklist is not verification that
its permissions were applied.

Apple's [Privacy Preferences Policy Control documentation](https://support.apple.com/guide/deployment/privacy-preferences-policy-control-payload-settings-dep38df53c2a/web)
requires device management to deploy privacy payloads. Some permissions can be
managed that way, but camera, microphone, and screen-recording access cannot
simply be pre-granted. This Mac is not MDM-enrolled (checked 2026-10-07); adding
management infrastructure solely for these switches is outside this lean setup.
Do not use unsupported defaults keys, edit TCC databases, disable SIP, or reset
all permissions. A targeted permission reset is not a persistent denial policy.

On 2026-10-07 Arc and Brave camera/microphone switches were turned off and
verified in System Settings. Other apps' camera/microphone grants were unchanged.
The repeated VS Code Local Network rows remain unresolved historical entries:
the app inventory found one real VS Code bundle, with its vendor designated
signing requirement. Do not infer that Nix caused the repeated rows or reset
working permissions without evidence.

Verified on this Mac on 2026-10-07: Screen Sharing is off after user-approved
shutdown; TCP 22/5900/3283 and UDP 5900/3283 have no listeners. Remote
Management, Remote Login, and Remote Application Scripting are off in Sharing.
Remote Management and application scripting remain device-owned switches;
the Nix activation enforces Screen Sharing and SSH off. Remote-user full-disk
access was off at the 2026-10-05 review. Passkey-site access is off for Arc, Brave, and Chrome;
Zen/Twilight retains access. These choices do not remove stored passkeys.
Finder favourites include Files, 00 Inbox, 10 Projects, and Developer.

`make doctor` checks disabled remote-access jobs, actual listening sockets,
and macOS update status; `make doctor ARGS="--full --section security"` isolates
these checks. Socket inspection failure is an unknown state, never proof of
closed ports. Routine checks use Apple's cached update catalog without network
requests, prompting, or installation; major upgrades are not treated as missing
same-major security updates. Tahoe older than 26.6.1 is explicitly flagged for
[CVE-2026-65400](https://support.apple.com/en-us/148170). A green check is not
a complete security audit or a guarantee that cached update metadata is fresh.

macOS itself is Apple-owned, not upgraded by `nix-switch`. On 2026-10-07 this
Mac still runs 26.5.2 and offers Tahoe 26.7.1; installation/restart is deferred
to the user tonight. Automatic update preferences do not prove patches were
installed. Screen Sharing was previously left on by request; that exception
has now been revoked.

Rechecked on 2026-10-08: the Mac still runs 26.5.2 (25F84); the deferred
installation has not happened. The security check again confirms Screen
Sharing/SSH disabled and no TCP 22/5900/3283 or UDP 5900/3283 listeners, but
fails the macOS-update check. Closing the service does not replace installing
the security update. No update or restart was initiated during cleanup.

The new Nix generation activated successfully from cmux on 2026-10-07 after
the user granted App Management. Home Manager's app-copy step and the remote
access policy both completed; `/run/current-system` points to the built
generation. Keep App Management on for the terminal used for activation;
do not bypass Home Manager's permission check.

The 2026-10-07 permission review found no enabled Full Disk Access grants.
Accessibility is enabled for Codex Computer Use, OneMenu, and Raycast.
After user-approved cleanup, screen recording is off for Arc, Brave, and
Slack; it remains enabled for Codex Computer Use, Discord, and Zen/Twilight.
Discord Input Monitoring is off and Discord was quit/reopened to apply the
change. The permission lists were rechecked; no Input Monitoring grants remain.
AirDrop is Contacts Only; AirPlay Receiver is Current User with a password.
Preserve Handoff rather than disabling all Apple cross-device services.

Network review: Screen Sharing/SSH ports are closed. Other wildcard TCP
listeners belong to Control Center (5000/7000), rapportd (49152), and Spotify
(57621); wildcard binding alone does not establish internet exposure. The
remaining observed TCP listeners are loopback-only. OrbStack was stopped,
so container port mappings remain unverified. The generic `sh` background
items are Nix/installer/key-loader jobs, not unidentified cleanup targets.
The three Xcode Git maintenance agents had no registered repositories and
were unloaded after approval. Their byte-identical plists are preserved in
`~/Private/Migrations/2026-10-07-git-maintenance-retirement/`; restore by copying
them back to `~/Library/LaunchAgents/` and bootstrapping the three user jobs.
Nix Git and its automatic maintenance settings are unchanged. Do not reset
macOS's background-item database.

Normal screenshots go to the iCloud-backed `~/Files/00 Inbox/Screenshots`.
For a deliberate private capture, press **Control-Shift-Command-4** and select
a region: macOS copies it to the clipboard rather than saving a file. Treat
clipboard history tools and pasting into another app as separate privacy
boundaries. Do not add a screenshot watcher or change the normal save target.

Manual shortcuts belong in Apple's Shortcuts app; non-secret recovery exports
belong in `~/Files/30 Resources/Shortcuts`. Re-select their folder destinations
after importing on another device; Mac folder bookmarks are not a promise of
portable iPhone or Linux execution. Keep scripting actions disabled when
native actions suffice.

- **New project** asks for a name and creates only a named folder under
  `10 Projects` (a story can use `Journalism/<Story Name>`), then reveals it.
  Add Sources/Working/Deliverables/Archive only inside that project when useful.
- **Capture to Inbox** appends typed text to `00 Inbox/Quick Capture.md`.
  Review and file the captured items; do not enter credentials or recovery codes.

Both shortcuts have non-empty recovery exports in the Shortcuts resource
folder. Capture to Inbox passed a real input/write test on 2026-10-05; New
project's actions and destination are configured but folder creation still
needs a first-use test. Neither shortcut runs as a background watcher.

The shared browser profile supplies a non-AI **Research source** Web Clipper
template at `~/.config/obsidian-web-clipper/research-source.json`. Import it
through the extension's settings, select the Files vault, and review the
metadata before saving. Default to Inbox rather than creating root-level
Clippings; for an identified story, select its `Sources` folder instead.
See [Obsidian's template instructions](https://obsidian.md/help/web-clipper/templates).

On this Mac the template is imported, targets Files explicitly, and is the
fallback template. A public-page capture into Inbox passed on 2026-10-05;
missing author/publication metadata stayed empty rather than being invented.
Browser Sync was reviewed but left off: Zen/Twilight is not signed in. Choose
the account and sync categories before uploading browser data; Apple Passwords
remains the credential source of truth.
