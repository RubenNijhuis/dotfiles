# CLAUDE.md

Nix-first, cross-platform personal environment for macOS, Linux, and WSL.
Home Manager owns shared user configuration and supported applications;
nix-darwin owns declarative macOS state. ChezMoi remains only for explicitly
transition-owned paths and Homebrew only for documented macOS package
exceptions. Launchd manages the remaining macOS automation.

## Structure

- `nix/` — flake modules: shared Home Manager configuration, capability
  profiles, and the macOS nix-darwin host.
- `chezmoi/` — residual transition source state only. Do not add new managed
  paths here; migrate one path at a time to Nix or keep it explicitly local.
- `setup/` — One-time setup scripts (key generation, hook installation, VS Code extensions, bloatware removal). Supported macOS defaults live in `nix/darwin/defaults.nix`.
- `ops/` — Ongoing operational scripts (update, clean, backup, brew sync, format, lint). Contains `automation/` for launchd-managed jobs.
- `health/` — Health checks and diagnostics (doctor, vscode parity, launchd contracts, ssh/gpg info).
- `tests/` — Script behavior and contract tests.
- `lib/` — Shared shell libraries sourced by all scripts.
- `hooks/` — Git hooks (pre-commit, commit-msg, pre-push).
- `launchd/` — Launchd plist templates with `__DOTFILES__`/`__HOME__` placeholders.
- `brew/` — documented macOS exceptions plus historical inventories. Nix is
  the default package source.
- `docs/` — Runbooks and generated references.
- `local/` — Machine-specific config (gitignored), with `.example` templates.

## Key Commands

- `make nix-check-all` — Evaluate every supported Nix target
- `make nix-build` / `make nix-switch` — Build / apply the current macOS configuration
- `make nix-home-switch NIX_HOME_HOST=<host>` — Apply a Linux or WSL Home Manager target
- `make update` — Refresh flake inputs and verify/build the Nix configuration
- `make update ARGS=--exceptions` — Update only the active profile's documented Homebrew exceptions
- `make update-legacy` — Run the old broad Homebrew/runtime/ChezMoi maintenance
- `make apply` / `make diff` — ChezMoi transition-only commands
- `make doctor` — Health summary + automation dashboard (default)
- `make doctor ARGS=--full` — Deep health check suite (~15 checks)
- `make doctor ARGS=--automation` — Just the automation dashboard
- `make doctor ARGS=--quick` — Just the short summary
- `make clean` — Remove caches, logs, .DS_Stores
- `make backup` — Backup dotfiles
- `make install` — Nix-first fresh-Mac installer
- `make install-legacy` — Temporary pre-Nix bootstrap for a transition recovery
- `make maint-check` — Lint + test + launchd validation
- `make help` — Show all targets (+ `help-setup`, `help-brew`, `help-launchd`, `help-test`)

## Lifecycle

```
Fresh machine → make install → make doctor / make maint-check
                           ↓
                 Nix check → build → switch
```

ChezMoi and `brew-sync` are compatibility tools while the remaining
transition-owned paths and documented macOS exceptions are retired. The default
installer and update workflow remain Nix-first.

## Script Contract

All scripts in `setup/`, `ops/`, and `health/` (except `health/checks/` and scripts marked `SCRIPT_VISIBILITY: launchd-internal`) must:
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
| `zsh` | `.zshrc`, `.zprofile`, `.zshenv` | Primary shell (completions, plugins, eval caching) | → shell, starship, atuin, fzf, mise, zoxide, gh, docker |
| `bash` | `.bashrc`, `.bash_profile` | Fallback shell for subshells | → shell, starship, atuin, zoxide, fzf, mise |
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
| `hushlogin` | `.hushlogin` | Suppress login banner in terminal | |
| `mise` | `.config/mise/config.toml` | Runtime version manager (Node LTS, Ruby latest) | |
| `ripgrep` | `.config/ripgrep/ripgreprc` | Ripgrep defaults (smart-case, max-columns) | |
| `claude` | `.claude/settings.json` | Claude Code settings and status line | |

### Shell Module Loading Order

```
zsh/bash startup
  → completions (zsh: cached 20h, bash: none)
  → plugins (Nix-managed zsh-autosuggestions and syntax-highlighting)
  → tool inits (zoxide, fzf, atuin, gh, docker; temporary mise compatibility may remain locally)
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

## Configuration Ownership

Home Manager modules and raw sources under `nix/config/` are the canonical
source for active shared configuration. The `chezmoi/` tree is a migration
inventory for paths not yet moved. Never let Home Manager and ChezMoi own the
same target. Secrets, SSH/GPG private material, application databases, and
machine-local overrides stay outside the Nix store.

## Brewfiles

Homebrew is an exception mechanism, not the default installer. `Brewfile.core`
contains Zen; `Brewfile.design` and `Brewfile.media` record Apple-Silicon
packages that are currently unavailable or broken in the pinned Nixpkgs.
Historical Brewfiles are inventory, never a default install. Prefer a Nix
capability profile when the pinned package supports the target host.

## Testing / Validation

Run `make maint-check` before committing. CI runs `make maint-check` plus docs-sync, vscode-parity, install dry-run, and Biome checks.
Pre-push hook runs shellcheck, docs-sync check, and Brewfile drift warning.

## Theme

Tokyo Night is used consistently across all tools: Ghostty, Neovim, tmux, Starship, FZF, bat, eza, btop, yazi, lazygit, spicetify, VS Code, man pages (LESS_TERMCAP in functions.sh).

## Local Overrides

Machine-specific config goes in `local/` (gitignored). Shell overrides: `~/.config/shell/local.sh`.
