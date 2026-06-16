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
- [x] tmux        → `chezmoi/dot_config/tmux/`
- [x] shell       → `chezmoi/dot_config/shell/` (6 .sh files)
- [x] spicetify   → `chezmoi/dot_config/spicetify/` (incl. Themes/TokyoNight)
- [x] claude      → `chezmoi/dot_claude/` (nested .git skipped; statusline-command.sh uses executable_ prefix to preserve +x)
- [x] nvim        → `chezmoi/dot_config/nvim/` (was stow package "vim"; LazyVim setup, 14 lua files + lockfile)
- [x] bash        → `chezmoi/dot_bashrc`, `chezmoi/dot_bash_profile`
- [x] zsh         → `chezmoi/dot_zshrc`, `dot_zprofile`, `dot_zshenv`
- [x] git         → `chezmoi/dot_gitconfig*`, `dot_gitignore_global`
- [x] ssh         → `chezmoi/private_dot_ssh/private_config{,.d/*}` (0700 dir, 0600 config)
- [x] gpg         → `chezmoi/private_dot_gnupg/private_gpg{,.agent}.conf`
- [x] ghostty     → `chezmoi/Library/Application Support/com.mitchellh.ghostty/config`
- [x] vscode      → `chezmoi/Library/Application Support/Code/User/{settings.json,extensions.txt}`

**All 23 stow packages migrated.** `config/` retains only gitignored
machine-local files (`config/shell/.config/shell/local.sh`, an orphan
`config/claude/.claude/.git`); stow infrastructure (setup/stow-all.sh,
make stow target, health/checks/core.sh check_stow) is still in place
and can be removed in a follow-up.

## Edge cases learned

- **0-byte source files are silently skipped** unless you prefix with
  `empty_` (so `.hushlogin` → `empty_dot_hushlogin`).
- **Anything in `chezmoi/` maps to `$HOME`.** Putting `README.md` in the
  source state would copy it to `~/README.md` on apply. Doc lives in
  `docs/` instead.
- **`~/.config/chezmoi/chezmoi.toml` is machine-local**, not committed.
  Each machine needs `sourceDir = "<absolute path to this repo>/chezmoi"`.
- **Executable bits use a filename prefix.** `executable_foo.sh` in the
  source state becomes `~/foo.sh` with `+x`. Hit by Claude's statusline.
- **Nested `.git` directories in stow packages don't transfer.** Claude's
  `.claude/.git/` was an orphan and would interfere with chezmoi's own
  git working tree if left in. Just don't copy it.
- **`private_` prefix on a directory sets 0700.** Used for `.ssh/` and
  `.gnupg/`. On a file: 0600. Chezmoi enforces these on every apply.
- **Library paths under `~/Library/...` need no encoding.** "Library"
  doesn't start with a dot, so it nests inside `chezmoi/Library/...`
  directly. Used for ghostty and VS Code.
