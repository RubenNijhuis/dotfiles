# Nix ownership matrix

This is the transition contract for this repository.  Nix should describe
reproducible machine state, while personal data, secrets, and application
databases remain outside it.

## Direct Nix ownership

These are safe to make declarative and portable through the flake and
Home Manager:

- Nix itself, flakes, caches, and trusted build settings.
- CLI packages and capability profiles: development, JavaScript, writing,
  design, media, gaming, and optional language toolchains.
- Portable desktop applications where the pinned package supports the host:
  Zen Twilight, Thunderbird, Obsidian, Signal, VS Code, Krita, and
  RawTherapee. Zen Twilight is a deliberately chosen preview channel; Zen
  itself owns its profile, Sync, and private browsing data.
  cmux, OrbStack, and Raycast belong in a separate macOS capability. Krita,
  RawTherapee, and HandBrake are documented Homebrew exceptions on this
  Apple-Silicon Mac until the pinned Nix packages work here.
- macOS defaults that `nix-darwin` supports: Finder, Dock, keyboard,
  trackpad, screen-capture defaults, and screen-lock policy.
- Portable program configuration once migrated one at a time: Git, Starship,
  Bat, ripgrep, direnv, zoxide, fzf, tmux, Yazi, Atuin, and Neovim.
- Non-secret editor settings and extensions, through a raw configuration file
  initially where Home Manager has no useful native module.

## Original repository coverage

The former ChezMoi source tree is retired; reusable configuration now lives
under `nix/config/`. “Native” means Home Manager has a useful declarative option;
“raw file” means Nix can own the file verbatim without pretending it knows the
application's schema.

On this Mac, 21 approved `.pre-nix` backups from `~/.config/` have been
consolidated under `~/Private/Migrations/2026-10-07-pre-nix-consolidation/`.
Other migration backups are not implied to have moved; see the exact inventory
and recovery caveat in [storage maintenance](storage-maintenance.md).

| Source / concern | Nix representation | State |
| --- | --- | --- |
| Git, global ignore | Home Manager Git module | active; prior files are `.pre-nix` backups |
| ripgrep, Bat, and the selected Bat theme | native Home Manager modules plus a raw theme file | active; prior files are `.pre-nix` backups |
| cmux and rendering preferences | `nix/home/cmux.nix` + `nix/config/ghostty/config` | active through the full Home Manager generation; updates use `make nix-switch`. New machines can adopt with `make nix-adopt PROFILE=cmux`. Sessions remain local. |
| Starship, Atuin | `nix/home/terminal.nix` | active; prior files are `.pre-nix` backups |
| tmux, Yazi, fzf, zoxide, sesh | `nix/home/navigation.nix` | active; prior files are `.pre-nix` backups. TPM is replaced with pinned Nix plugins; Yazi has portable open/clipboard fallbacks. |
| Btop, LazyGit | `nix/home/terminal-apps.nix` | active; prior files are `.pre-nix` backups. Btop's exit-time config writes are disabled; existing shell aliases remain in place. |
| Eza theme | `nix/home/terminal-apps.nix` raw file | active; existing shell aliases remain in place |
| Neovim | `nix/home/editors.nix` + `editor-plugins.nix` | Nix owns the binary, bootstrap, plugin graph, native completion library, and selected compiled parsers/queries. Extras are declared once in `lazyvim.json`. Bash/Lua tools and formatters come from the developer profile; other language tools belong in project environments. Mason is a manual fallback, not an automatic installer. Copilot remains enabled but sign-in is private/app-owned. |
| VS Code settings and extension manifest | `nix/home/vscode.nix` + `nix/config/vscode/` | settings apply on graphical desktop hosts; extensions install through `make vscode-setup` because marketplace binaries remain application-managed state. |
| Raycast preferred-application launchers | `nix/home/raycast.nix` Script Commands | active on macOS after the command directory is registered once in Raycast; private Raycast state and `.rayconfig` exports remain outside Git. |
| `.hushlogin`, repository Git hooks | `nix/home/editors.nix` + `make hooks` | active; neither needs ChezMoi ownership. |
| Global Mise/Ruby | retired; future projects use pinned devShells | global config archived locally; shell hooks and shim PATH removed. Ruby 4.0.5 moved recoverably to Trash; older Node/Yarn installs remain for project compatibility. |
| Shared shell modules | `nix/home/shell-modules.nix` raw files | active; startup files consume these links |
| Shell startup environment | Home Manager Zsh/Bash and session modules | active; legacy ChezMoi sources were removed after the handoff, while private `.pre-nix` backups remain outside Git |
| Spotify theming | `nix/profiles/leisure.nix` + `nix/config/spicetify/` | active on this Mac: CLI 2.45.3 and TokyoNight files; original theme files are `.pre-nix` backups. Runtime config, custom apps, and Spotify backups stay writable/app-owned. |
| SSH/GPG preferences | `nix/home/ssh-and-gpg.nix` + `nix/config/{ssh,gpg}/` | active and verified; originals preserved as `.pre-nix`. GnuPG is Nix-owned; newer Mac pinentry remains a documented Homebrew exception. See [retirement and recovery](chezmoi-migration.md). |
| SSH private keys, GPG keyrings, private shell override | encrypted/local only | secrets and mutable trust state are excluded from Nix; `~/.config/shell/local.sh` remains unchanged, user-owned, and mode 0600 |
| macOS defaults | `nix/darwin/defaults.nix` | active; no competing ChezMoi default script remains |

## Kept outside Nix

The following are intentionally local or encrypted, never plain Nix source:

- Keychain entries, private SSH keys, API tokens, recovery codes, and chezmoi
  secret data.
- Application databases, browser profiles, mail stores, game libraries, and
  caches.
- Apple ID/iCloud, device enrollment, biometric data, FileVault keys, Wi-Fi
  credentials, and software licenses.
- Calendar account credentials, event databases, invitation history, and AI
  connector permissions. Nix installs clients only; the calendar service is
  configured in the operating system or Thunderbird with an app password.
- Shortcuts' internal database. Export approved personal shortcuts as
  `.shortcut` files for backup; use Shortcuts itself to import them.

## Migration order

1. Activate the minimal darwin/Home Manager configuration successfully.
2. Keep `nix/darwin/defaults.nix` as the sole owner for supported macOS
   preferences; keep unsupported personal choices local rather than adding a
   competing default script.
3. Adopt one coherent configuration profile at a time into Home Manager only
   after an approved recoverable backup; verify actual links and executables.
4. Move editor and application settings as explicit raw `home.file` entries
   only after a backup and collision check.
5. Prefer Nix for every package available in the pinned cross-platform package
   set. Homebrew is limited to bootstrap needs and documented Nix-unavailable
   macOS exceptions; do not reintroduce ChezMoi or competing ownership.

## Rules that prevent drift

- One owner per path: Nix/Home Manager, an application, or the user;
  never more than one.
- Capability profiles select packages; they do not silently install every
  possible tool on every machine.
- `Files`, `Private`, and project repositories contain durable work. Downloads,
  Desktop, and caches are intake or temporary locations.
- Verify shared changes with `make nix-check-all` before a system switch and
  make changes in small, reviewable commits.
