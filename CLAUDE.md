# CLAUDE.md

macOS-only dotfiles repo. Uses GNU Stow for symlink management, Homebrew for packages, launchd for automation. No Linux/cross-platform support.

## Structure

- `config/` — Config packages symlinked into `$HOME` via GNU Stow. Each subdirectory mirrors home directory structure.
- `setup/` — One-time and repeated setup scripts (stow, macos-defaults, key generation, hook installation).
- `ops/` — Ongoing operational scripts (update, clean, backup, brew sync, format, lint). Contains `automation/` for launchd-managed jobs.
- `health/` — Health checks and diagnostics (doctor, vscode parity, launchd contracts, ssh/gpg info).
- `tests/` — Script behavior and contract tests.
- `lib/` — Shared shell libraries sourced by all scripts.
- `hooks/` — Git hooks (pre-commit, commit-msg, pre-push).
- `launchd/` — Launchd plist templates with `__DOTFILES__`/`__HOME__` placeholders.
- `brew/` — Brewfiles split by profile (see below).
- `docs/` — Runbooks and generated references.
- `local/` — Machine-specific config (gitignored), with `.example` templates.

## Key Commands

- `make update` — Update packages, runtimes, and re-stow configs
- `make stow` / `make unstow` — Manage symlinks
- `make status` — Quick actionable system status
- `make doctor` — Comprehensive health check
- `make clean` — Remove caches, logs, .DS_Stores
- `make backup` — Backup dotfiles
- `make install` — Full bootstrap (new machine)
- `make maint-check` — Lint + test + launchd validation
- `make help` — Show all targets (+ `help-setup`, `help-brew`, `help-launchd`, `help-test`)

## Lifecycle

```
Fresh machine → install.sh → make stow → make doctor → make ops-status
                                ↓
                         make brew-sync (ongoing)
                                ↓
                         make maint-check (pre-push)
```

## Script Contract

All scripts in `setup/`, `ops/`, and `health/` (except `health/checks/` and `ops/automation/launchd/`) must:
- Support `--help` (exit 0)
- Reject unknown flags (non-zero exit)
- Accept `--no-color` for output formatting

Exception: scripts marked with `# SCRIPT_VISIBILITY: launchd-internal`.

## Commit Conventions

Conventional commits: `type(scope): summary` or `type: summary`. Max 72 chars.
Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
Do NOT include Co-Authored-By lines.

## Tool Registry

Each config package maps to a tool config. Cross-tool dependencies are noted with `→`.

| Package | Config Path | Purpose | Dependencies |
|---------|------------|---------|--------------|
| `zsh` | `.zshrc`, `.zprofile`, `.zshenv` | Primary shell (completions, plugins, eval caching) | → shell, starship, atuin, fzf, fnm, zoxide, gh, docker |
| `bash` | `.bashrc`, `.bash_profile` | Fallback shell for subshells | → shell, starship, atuin, zoxide, fzf, fnm |
| `shell` | `.config/shell/{exports,aliases,functions,path}.sh` | Shared shell modules (sourced by zsh+bash) | → bat, eza, rg, fd, fzf, nvim, btop, yazi, sesh |
| `vim` | `.config/nvim/` (LazyVim) | Neovim editor (init.lua + plugin configs) | → tmux (vim-tmux-navigator), git (gitsigns, diffview) |
| `tmux` | `.config/tmux/tmux.conf` | Terminal multiplexer (tpm plugins) | → vim (vim-tmux-navigator), sesh+fzf (session picker) |
| `git` | `.gitconfig`, `.gitconfig-{personal,work}`, `.gitignore_global` | Git config with work/personal split via `includeIf` | → ssh (keys), gpg (signing), delta (diffs) |
| `ssh` | `.ssh/config`, `.ssh/config.d/{common,personal,work}.conf` | SSH with modular includes | → macOS Keychain |
| `gpg` | `.gnupg/{gpg,gpg-agent}.conf` | GPG signing with pinentry-mac | → macOS Keychain |
| `starship` | `.config/starship.toml` | Prompt (Tokyo Night palette, git/lang indicators) | |
| `ghostty` | `Library/.../com.mitchellh.ghostty/config` | Terminal emulator (FiraCode, 92% opacity) | |
| `lazygit` | `.config/lazygit/config.yml` | Git TUI | → delta (pager) |
| `atuin` | `.config/atuin/config.toml` | Shell history with fuzzy search (local-only) | |
| `bat` | `.config/bat/config` + theme | `cat` replacement (Tokyo Night) | |
| `eza` | `.config/eza/theme.yml` | `ls` replacement (Tokyo Night) | |
| `btop` | `.config/btop/btop.conf` + theme | System monitor (Tokyo Night) | |
| `yazi` | `.config/yazi/{yazi,theme,keymap}.toml` | File manager with zoxide integration | → bat (previews), zoxide, editor |
| `sesh` | `.config/sesh/sesh.toml` | Tmux session manager | → tmux, fzf, zoxide |
| `spicetify` | `.config/spicetify/` | Spotify theming (Tokyo Night) | |
| `vscode` | `Library/.../Code/User/{settings.json,extensions.txt}` | VS Code (Biome, ESLint, Tokyo Night) | |
| `dotnet` | `path.sh`, `exports.sh` | .NET SDK (version-pinned, Rider as IDE) | → omnisharp (Neovim LSP) |
| `claude` | `.claude/skills/` | Claude CLI skills (commit, review-pr, fix-issue) | |

### Shell Module Loading Order

```
zsh/bash startup
  → HOMEBREW_PREFIX (cached)
  → completions (zsh: cached 20h, bash: none)
  → plugins (zsh-autosuggestions, syntax-highlighting deferred)
  → tool inits (fnm, zoxide, fzf, atuin, rbenv, gh, docker — all cached in ~/.cache/zsh/)
  → shell/path.sh (zsh-only: typeset -U, path=())
  → shell/exports.sh (env vars, FZF colors, eza icons)
  → shell/aliases.sh (cat→bat, ls→eza, grep→rg, vim→nvim, top→btop)
  → shell/functions.sh (mkcd, fe, proj, newproj, y, fco)
  → starship init (cached)
  → local.sh (machine-specific overrides)
```

### Cross-Tool Integration Points

- **vim-tmux-navigator**: Neovim plugin + tmux plugin share `C-hjkl` for seamless pane/split navigation
- **sesh + tmux + fzf**: `T` binding in tmux launches sesh with fzf picker (ctrl-a/t/g/x/d/f filters)
- **delta**: Used by both git (pager) and lazygit (pager) for consistent diff rendering
- **shell functions → tools**: `fe()` uses fd+fzf+bat+$EDITOR; `proj()` uses fd+git+fzf+$EDITOR; `y()` wraps yazi; `fco()` uses git+fzf
- **git includeIf**: Directory-based work/personal split auto-selects SSH key and email
- **FZF colors**: Set globally in `exports.sh`, inherited by all FZF consumers (fzf, sesh picker, shell functions)

## Config Packages

Packages live in `config/`. Each subdirectory is a stow package symlinked into `$HOME`, mirroring the home directory structure. Use `make stow-report` to preview conflicts.

## Brewfiles

Split by profile in `brew/`:
- `Brewfile.cli` — Shared CLI tools
- `Brewfile.apps` — Shared GUI apps
- `Brewfile.vscode` — VS Code extensions (must stay in sync with `config/vscode/.../extensions.txt`)
- `Brewfile.personal` — Personal-only packages
- `Brewfile.work` — Work-only packages

When adding packages to Brewfiles, also run `brew install <package>` to install immediately.

## Testing / Validation

Run `make maint-check` before committing. CI runs `make maint-check` plus docs-sync, vscode-parity, install dry-run, and Biome checks.
Pre-push hook runs shellcheck, docs-sync check, and Brewfile drift warning.

## Theme

Tokyo Night is used consistently across all tools: Ghostty, Neovim, tmux, Starship, FZF, bat, eza, btop, yazi, lazygit, spicetify, VS Code, man pages (LESS_TERMCAP in functions.sh).

## Local Overrides

Machine-specific config goes in `local/` (gitignored). Shell overrides: `~/.config/shell/local.sh`.
