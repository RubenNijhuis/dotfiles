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

Verified on this Mac on 2026-10-05: Remote Login and remote-user full-disk
access are off. Screen Sharing remains on at the user's request because a
session was connected. Passkey-site access is off for Arc, Brave, and Chrome;
Zen/Twilight retains access. These choices do not remove stored passkeys.
Finder favourites include Files, 00 Inbox, 10 Projects, and Developer.

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
