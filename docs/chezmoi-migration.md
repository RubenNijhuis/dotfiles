# ChezMoi retirement

ChezMoi is retired. Nix/Home Manager is the sole declarative configuration
owner; applications and the user own their writable/private state. The old
source tree, package, Make targets, health checks, and template tests are gone.
The current contract is the [Nix ownership matrix](nix-ownership-matrix.md).

## Ownership and recovery

- SSH/GPG preferences live in `nix/home/ssh-and-gpg.nix` and `nix/config/`.
  Keys, trust databases, known hosts, and agent sessions remain local.
  The five original preference files remain as adjacent `.pre-nix` backups.
- Spotify's reusable TokyoNight files and CLI belong to the opt-in
  `nix/profiles/leisure.nix`. This Mac imports it; WSL and other hosts do not
  receive Spotify theming unless explicitly selected. The two theme originals
  remain as adjacent `.pre-nix` backups.
- `config-xpui.ini`, custom apps, Spotify backups, and account data remain
  writable and application-owned. Edit theme source in `nix/config/spicetify/`;
  `spicetify color` cannot edit the read-only Nix palette.
- `~/.config/shell/local.sh` stays user-owned, with mode 0600 and unchanged
  contents. Bash/Zsh source it optionally; it is never rendered into Nix.
  Restore it locally on a new machine, never through Git.
- Global Mise/Ruby activation is retired. No Ruby manifest was found in the
  active personal/work code scan. A future Ruby project should pin a devShell;
  Ruby 4.0.5 was moved recoverably to Trash after approval. Older Node/Yarn
  installations remain for existing project compatibility.

The approved local-only migration archive is:
`~/Private/Migrations/2026-10-03-chezmoi-retirement/`.
It contains the old `chezmoi/` configuration (possibly secret values) and
`mise/config.toml`. Keep it private and include it in an encrypted off-device
backup when available. Do not restore it as active ChezMoi ownership.

After any restore or adoption, run `make nix-switch` and verify links and
actual executable versions. `make gpg-check` tests signing/encryption using
disposable keys only; it does not prove compatibility with personal keys or
replace a real recovery test. Mac pinentry remains a documented Homebrew
exception until Nix supplies a suitable version.
