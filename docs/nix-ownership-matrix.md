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
  Thunderbird, Obsidian, Signal, VS Code, cmux, Krita, and RawTherapee.
  OrbStack and Raycast belong in a separate macOS capability. Krita,
  RawTherapee, and HandBrake are documented Homebrew exceptions on this
  Apple-Silicon Mac until the pinned Nix packages work here.
- macOS defaults that `nix-darwin` supports: Finder, Dock, keyboard,
  trackpad, screen-capture defaults, and screen-lock policy.
- Portable program configuration once migrated one at a time: Git, Starship,
  Bat, ripgrep, direnv, zoxide, fzf, tmux, Yazi, Atuin, Neovim, and Ghostty.
- Non-secret editor settings and extensions, through a raw configuration file
  initially where Home Manager has no useful native module.

## Original repository coverage

The existing `chezmoi/` tree is not being discarded.  It is the migration
inventory below.  “Native” means Home Manager has a useful declarative option;
“raw file” means Nix can own the file verbatim without pretending it knows the
application's schema.

| Source / concern | Nix representation | State |
| --- | --- | --- |
| Git, global ignore | Home Manager Git module | active; prior files are `.pre-nix` backups |
| ripgrep, Bat | native Home Manager modules | active; prior files are `.pre-nix` backups |
| Starship, Atuin | `nix/home/terminal.nix` | active; prior files are `.pre-nix` backups |
| tmux, Yazi, fzf, zoxide, sesh | `nix/home/navigation.nix` | active; prior files are `.pre-nix` backups. TPM is replaced with pinned Nix plugins; Yazi has portable open/clipboard fallbacks. |
| Btop, LazyGit | `nix/home/terminal-apps.nix` | active; prior files are `.pre-nix` backups. Btop's exit-time config writes are disabled; existing shell aliases remain in place. |
| Eza theme | `nix/home/terminal-apps.nix` raw file | active; existing shell aliases remain in place |
| Neovim configuration and binary | `nix/home/editors.nix` | active. Lazy.nvim/Mason data stays local until the plugin graph is pinned; its writable runtime lockfile is in local state. Copilot remains unchanged pending an explicit FOSS replacement choice. |
| VS Code settings and extension manifest | `nix/home/editors.nix` + `nix/config/vscode/` | active; extensions install through `make vscode-setup` because marketplace binaries remain application-managed state. |
| `.hushlogin`, repository Git hooks | `nix/home/editors.nix` + `make hooks` | active; neither needs ChezMoi ownership. |
| `dot_config/mise/` | temporary local compatibility state | not installed on new machines; this Mac retains it only while its active global Ruby shim is migrated to a project environment or retired |
| Shared shell modules | `nix/home/shell-modules.nix` raw files | active; startup files consume these links |
| `dot_zsh*`, `dot_bash*`, startup environment | Home Manager Zsh/Bash and session modules with canonical raw source | active; prior startup files are private `.pre-nix` backups and fresh Zsh/Bash sessions resolve the Nix-managed tools |
| `dot_config/spicetify/`, `dot_claude/` | app-specific opt-in configuration | retain outside the core profile until each app is retained |
| `private_dot_ssh/`, `private_dot_gnupg/`, `local.sh.tmpl` | encrypted/local only | explicitly excluded from Nix |
| macOS defaults | `nix/darwin/defaults.nix` | active; the narrow ChezMoi script keeps only opt-in local Dock placement and Library visibility |

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
   preferences; retain only the narrow ChezMoi script for settings Nix cannot
   model cleanly.
3. Move one coherent configuration profile at a time from chezmoi to Home
   Manager, verify its target, then stop managing that same target through
   chezmoi.
4. Move editor and application settings as explicit raw `home.file` entries
   only after a backup and collision check.
5. Prefer Nix for every package available in the pinned cross-platform package
   set. Homebrew is limited to bootstrap needs and documented Nix-unavailable
   macOS exceptions; ChezMoi gains no new owned paths.

## Rules that prevent drift

- One owner per path: Nix/Home Manager, chezmoi, an application, or the user;
  never more than one.
- Capability profiles select packages; they do not silently install every
  possible tool on every machine.
- `Files`, `Private`, and project repositories contain durable work. Downloads,
  Desktop, and caches are intake or temporary locations.
- Verify shared changes with `make nix-check-all` before a system switch and
  make changes in small, reviewable commits.
