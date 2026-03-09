# CLAUDE.md

macOS-only dotfiles repo. Uses GNU Stow for symlink management, Homebrew for packages, launchd for automation. No Linux/cross-platform support.

## Structure

- `stow/` — Config packages symlinked into `$HOME`. Each subdirectory mirrors home directory structure.
- `scripts/` — Operational scripts grouped by domain (`automation/`, `bootstrap/`, `health/`, `maintenance/`, `migration/`, `backup/`, `info/`, `docs/`), plus `lib/` and `tests/`.
- `brew/` — Brewfiles split by profile (see below).
- `templates/` — Launchd plist templates and local override templates.
- `docs/` — Runbooks and generated references.
- `macos/` — macOS system defaults.
- `git-hooks/` — Pre-commit, commit-msg, pre-push hooks.
- `local/` — Machine-specific config (gitignored).

## Key Commands

- `make install` — Full bootstrap (brew + stow + macos defaults)
- `make stow` / `make unstow` — Manage symlinks
- `make doctor` — Comprehensive health check
- `make maint-check` — Lint + test + launchd validation
- `make bootstrap-verify` — Strict reliability checks
- `make format` — Format all files (EditorConfig)
- `make docs-sync` — Verify generated docs are current
- `make update` — Update packages and re-stow configs

## Script Contract

All scripts in `scripts/**` (except `lib/` and `tests/`) must:
- Support `--help` (exit 0)
- Reject unknown flags (non-zero exit)
- Accept `--no-color` for output formatting

Exception: scripts marked with `# SCRIPT_VISIBILITY: launchd-internal`.

## Commit Conventions

Conventional commits: `type(scope): summary` or `type: summary`. Max 72 chars.
Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
Do NOT include Co-Authored-By lines.

## Stow Packages

Packages live in `stow/`. Each subdirectory is a stow package symlinked into `$HOME`, mirroring the home directory structure. Use `make stow-report` to preview conflicts.

## Brewfiles

Split by profile in `brew/`:
- `Brewfile.cli` — Shared CLI tools
- `Brewfile.apps` — Shared GUI apps
- `Brewfile.vscode` — VS Code extensions
- `Brewfile.personal` — Personal-only packages
- `Brewfile.work` — Work-only packages

When adding packages to Brewfiles, also run `brew install <package>` to install immediately.

## Testing / Validation

Run `make maint-check` before committing. CI runs `make lint-shell` and `make doctor-ci`.
Pre-push hook runs shellcheck, docs-sync check, and Brewfile drift warning.

## Theme

Tokyo Night is used consistently across all tools: Ghostty, Neovim, tmux, Starship, FZF, bat.

## Local Overrides

Machine-specific config goes in `local/` (gitignored). Shell overrides: `~/.config/shell/local.sh`.
