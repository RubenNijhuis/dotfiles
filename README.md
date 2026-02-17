# Dotfiles

Personal macOS/Linux development environment managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone https://github.com/<user>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` handles profile selection (`personal` or `work`), package install, stow, runtime setup, and optional macOS defaults.

## Core Commands

```bash
make help          # list commands
make install       # full setup
make update        # update packages + restow
make stow          # apply all stow packages
make stow-report   # preview stow conflicts (no changes)
make unstow        # remove stow links
make doctor        # full health checks
make doctor-quick  # fast health checks
make check-scripts # bash -n + shellcheck on scripts
make test-scripts  # lightweight script behavior tests
make maint-check   # check-scripts + test-scripts
make maint         # maint-check + optional maint-sync
make format        # EditorConfig + Biome formatting
make hooks         # install git hooks
```

## Repository Layout

```text
dotfiles/
├── stow/        # user config packages linked into ~
├── scripts/     # automation and maintenance scripts
├── templates/   # templates and setup helpers
├── brew/        # Brewfile.common, Brewfile.personal, Brewfile.work
├── docs/        # focused guides
└── macos/       # macOS defaults script
```

## Profiles and Package Management

- Profile is stored in `~/.config/dotfiles-profile`.
- Brewfiles are split by scope:
  - `brew/Brewfile.common`
  - `brew/Brewfile.personal`
  - `brew/Brewfile.work`

Typical workflow:

```bash
# install/update from Brewfiles
make install
make update

# sync manually installed packages back to Brewfiles
make brew-sync
make brew-audit
```

## Formatting and Quality Gates

- `.editorconfig` handles core formatting rules (indent, line endings, whitespace).
- `biome.json` handles JS/TS/JSON/Markdown formatting/linting.
- Git hooks run at commit/push:
  - `git-hooks/pre-commit`
  - `git-hooks/pre-push`

Install hooks:

```bash
make hooks
```

Hook details:

- `docs/git-hooks.md`

## VS Code

Setup:

```bash
make vscode-setup
```

Source files:

- `stow/vscode/Library/Application Support/Code/User/settings.json`
- `stow/vscode/Library/Application Support/Code/User/extensions.txt`

Guide:

- `docs/vscode.md`

## SSH and GPG

```bash
make ssh-setup
make ssh-info
make migrate-ssh

make gpg-setup
make gpg-info
```

Guides:

- `templates/ssh/README.md`
- `templates/gpg/README.md`

## Developer Directory

Expected structure:

```text
~/Developer/
├── personal/{projects,experiments,learning}
├── work/{projects,clients}
└── archive/
```

Migration helpers:

```bash
make validate-repos
make migrate-dev-dryrun
make migrate-dev
make complete-migration
```

Guide:

- `docs/developer-migration.md`

## LaunchD Automation

Use the unified manager:

```bash
~/dotfiles/scripts/launchd-manager.sh list
~/dotfiles/scripts/launchd-manager.sh install-all
~/dotfiles/scripts/launchd-manager.sh status
~/dotfiles/scripts/launchd-manager.sh install ai-startup-selector
```

Built-in agent setup helpers:

```bash
make backup-setup
make backup-status
make doctor-setup
make doctor-status
```

Docs:

- `templates/launchd/README.md`
- `docs/launchd-examples.md`
- `docs/scripts-reference.md`

## Backups and Restore

```bash
make backup
make restore
```

Backups are kept in `~/.dotfiles-backup/` with timestamped directories and rotation logic.

## Health Checks

```bash
make doctor
make doctor-quick
bash scripts/doctor.sh --section backup --no-color
```

Doctor runbook:

- `docs/doctor-guide.md`
- `docs/scripts-reference.md`

## Troubleshooting

### Stow conflicts

```bash
make unstow && make stow
```

### Homebrew shellenv not loaded

```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

### Re-run installation safely

`install.sh` is idempotent and supports checkpoints; re-running is safe.

Useful flags:

```bash
./install.sh --yes
./install.sh --dry-run
./install.sh --from-step 7
```

## Focused Docs

- `docs/git-hooks.md`
- `docs/doctor-guide.md`
- `docs/vscode.md`
- `docs/editorconfig.md`
- `docs/developer-migration.md`
- `docs/launchd-examples.md`
- `docs/scripts-reference.md`
