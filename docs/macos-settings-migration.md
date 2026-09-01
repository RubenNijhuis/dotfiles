# macOS settings migration

Nix should own durable, repeatable preferences—not every byte of the user
profile. The first declarative macOS settings module is
`nix/darwin/defaults.nix`.

## Nix-owned settings

- Finder, Dock, keyboard-repeat, text-substitution, trackpad, appearance,
  screenshot, and screen-lock preferences supported by nix-darwin.
- Touch ID for `sudo`.
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

The supported preferences are now owned by `nix/darwin/defaults.nix`. The
remaining chezmoi script is intentionally narrow: an opt-in local Dock layout
and a filesystem visibility flag which nix-darwin cannot model cleanly. It
must not add another write for a preference already represented in Nix.

## Future additions, reviewed one category at a time

1. Finder sidebar and Dock apps after selecting the lean everyday app core.
2. Keyboard modifier mappings and Control Center preferences if their
   hardware-specific constraints are understood.
3. Homebrew ownership through nix-darwin after the Homebrew catalog is
   reduced and observed.
4. Exported Shortcuts for durable manual workflows; use Shortcuts first for
   user-facing automation, and avoid hidden background file watchers.
