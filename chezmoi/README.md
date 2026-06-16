# chezmoi source state

Migration target. `stow` still owns most of `config/`; this directory holds
the chezmoi-managed slice. They coexist via `~/.config/chezmoi/chezmoi.toml`:

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

Migrated (in chezmoi/, also still in config/):
- [x] hushlogin   → `chezmoi/dot_hushlogin`
- [x] starship    → `chezmoi/dot_config/starship.toml`
- [x] ripgrep     → `chezmoi/dot_config/ripgrep/`
- [x] mise        → `chezmoi/dot_config/mise/`
- [x] bat         → `chezmoi/dot_config/bat/`

Stow-only (not yet migrated):
- atuin, btop, eza, gpg, ghostty, git, lazygit, sesh, shell, ssh,
  spicetify, tmux, vim, vscode, yazi, zsh, bash, claude

Cutover for the first batch happens by running steps 3-5 above when you're
ready. Until then, both tools live side-by-side and the symlinks are still
authoritative in `$HOME`.
