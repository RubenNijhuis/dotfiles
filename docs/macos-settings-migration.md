# macOS settings policy and audit evidence

`nix/darwin/defaults.nix` owns supported, repeatable preferences. For the
restore sequence use the [new-Mac checklist](runbooks/new-mac-recovery.md);
for app-specific exports and sync use the [application catalog](application-catalog.md).
Dated audits below record earlier checks, not live verification of this Mac.

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
- The old Lix installer repair hook is disabled/unloaded only when its
  executable is absent; the daemon, volume-mount service and hook plist remain.
  Restoring the installer does not automatically re-enable a retired hook.
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

New preferences need a demonstrated use and a supported restore path.
Do not snapshot whole application preference domains: they can contain account
identifiers, cloud state and device-specific data. Use Shortcuts first for
user-facing automation; avoid hidden background file watchers.

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

The 2026-10-07 manual review disabled retired browsers' camera/microphone and
passkey-site access; screen recording remained enabled for Codex Computer Use,
Discord and Zen/Twilight. Input Monitoring had no grants. Accessibility,
AirDrop, AirPlay and Handoff choices remain device-owned; this historical
review is not proof of their current state. Repeated permission/background
rows do not prove duplicate installed apps. Never reset those databases just
to tidy their display. Keep App Management enabled for the terminal used for
activation; do not bypass Home Manager's permission check.

### Current settings and background audit — 2026-10-13

- Stored Finder destination, screenshot destination/file target, Dock autohide,
  spelling correction, immediate screen-lock password and network/USB Finder
  metadata preferences match the Nix baseline. Reading a preference does not
  verify every corresponding GUI behaviour.
- Firewall and stealth mode are enabled. Screen Sharing and SSH jobs are
  disabled; no TCP 22/5900/3283 or UDP 5900/3283 listeners were found.
- FigmaAgent, Raycast's backend and the active website research API listen on
  loopback only. Apple's Control Center (5000/7000) and rapportd (63710) bind
  more broadly; these are not Screen Sharing, and the audit does not establish
  internet reachability. Preserve the chosen continuity features.
- Apple's socket-activated FTP proxy owns loopback port 8021, with zero runs;
  it is not an exposed FTP server or a dangling third-party process.
- OrbStack is stopped and Docker sockets are absent. Container forwarding
  remains unverified; do not start containers merely to complete an audit.
- The old `systems.lix.nix-installer.nix-hook` job waits for the absent
  `/nix/lix-installer`. It is separate from the healthy Nix daemon and store
  mount service. Its automatic shell-repair purpose is documented in the
  [installer source](https://git.lix.systems/lix-project/lix-installer/src/branch/main/src/action/macos/create_nix_hook_service.rs).
  Its exact retirement was approved and saved as a guarded Nix activation
  policy; the healthy-installer case is untouched. Doctor's launchd section
  warns when this job is loaded without its executable; Doctor never disables it.
  Generation 60 applied the policy: the job is disabled and no longer loaded;
  its plist remains in place, and the daemon/store-mount service are unchanged.
  Re-enabling it after restoring a trusted installer requires a deliberate
  `sudo launchctl enable system/systems.lix.nix-installer.nix-hook` and bootstrap
  of the retained plist, not a whole-Nix reinstall.
- Google and Oracle updater executables still have corresponding installed
  applications; their idle state is not an orphan diagnosis. Two empty
  Keystone plists are inert debris, not running jobs. No files were removed.

`make doctor ARGS="--full --section security"` checks remote-access policy,
listening sockets and Apple's cached update catalog without installing updates.
An inspection failure means unknown, not closed or up to date. macOS is still
26.5.2 (25F84); update/restart remains deferred and is not performed by Nix.
A clean listener audit is not a full security audit or evidence of patching.

### Application settings audit — 2026-10-13

VS Code's shared settings are Nix-linked; its extension IDs are declared while
marketplace versions remain app-owned. The subsequent approved retirement
removed six unlisted language extensions and preserved Lua/Nginx; see
[the editor setup](vscode.md) for the verified outcome. HTTP/HTTPS handlers
selected Zen and mailto selected Thunderbird at this audit. Raycast's
preferred-app scripts were Nix-linked; its hotkey and directory registration
remain editable app settings. Current restore instructions belong in the
[application catalog](application-catalog.md).

OneMenu's non-secret native preferences currently record automatic updates
and launch at login on, its window manager off, and spacing 0.5. These are
restore reference values, not a supported stable export contract or evidence
that writing a preference recreates login-item registration. Recreate them
through OneMenu on a new Mac; keep account/CloudKit state outside the repo.

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
