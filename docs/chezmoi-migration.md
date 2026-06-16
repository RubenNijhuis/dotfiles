# chezmoi migration

Tracker for the move from `stow` (under `config/`) to `chezmoi` (under
`chezmoi/`). Both tools coexist on this branch; each package crosses over
one at a time. They share the repo via `~/.config/chezmoi/chezmoi.toml`:

```toml
sourceDir = "~/Developer/personal/projects/dotfiles/chezmoi"
```

## Why chezmoi

Stow's symlink farming caused real problems in this repo: broken-symlink
detection, package "ownership" conflicts, the two-clones problem. chezmoi
copies files into `$HOME` (no symlinks), supports templating for
machine-specific variance, and handles secrets cleanly. See the migration
plan below for what's moved so far.

## Migration plan

Per-package recipe (run by hand for now; no automation yet):

```sh
# 1. Copy the file into chezmoi source state, encoding dots as dot_.
cp config/<pkg>/<path> chezmoi/<chezmoi-path>

# 2. Preview the change. Should show a symlink->file replacement.
chezmoi diff

# 3. Unstow the package so $HOME stops pointing at config/<pkg>/.
make unstow PACKAGES=<pkg>      # or stow -D -d config -t $HOME <pkg>

# 4. Apply chezmoi (creates the actual file at the destination).
chezmoi apply

# 5. Once verified working, remove config/<pkg>/ from stow.
rm -rf config/<pkg>
```

## Status

Cut over to chezmoi (deleted from `config/`):
- [x] hushlogin   → `chezmoi/empty_dot_hushlogin` (empty_ attr required for 0-byte files)
- [x] starship    → `chezmoi/dot_config/starship.toml`
- [x] ripgrep     → `chezmoi/dot_config/ripgrep/`
- [x] mise        → `chezmoi/dot_config/mise/`
- [x] bat         → `chezmoi/dot_config/bat/`
- [x] btop        → `chezmoi/dot_config/btop/`
- [x] eza         → `chezmoi/dot_config/eza/`
- [x] lazygit     → `chezmoi/dot_config/lazygit/`
- [x] yazi        → `chezmoi/dot_config/yazi/` (pre-existing yazi.toml parse error — yazi schema changed; needs separate fix)
- [x] sesh        → `chezmoi/dot_config/sesh/`
- [x] atuin       → `chezmoi/dot_config/atuin/`

Stow-only (not yet migrated):
- bash, claude, ghostty, git, gpg, shell, spicetify, ssh, tmux, vim,
  vscode, zsh

## Edge cases learned

- **0-byte source files are silently skipped** unless you prefix with
  `empty_` (so `.hushlogin` → `empty_dot_hushlogin`).
- **Anything in `chezmoi/` maps to `$HOME`.** Putting `README.md` in the
  source state would copy it to `~/README.md` on apply. Doc lives in
  `docs/` instead.
- **`~/.config/chezmoi/chezmoi.toml` is machine-local**, not committed.
  Each machine needs `sourceDir = "<absolute path to this repo>/chezmoi"`.
