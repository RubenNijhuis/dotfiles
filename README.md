# Dotfiles

macOS laptop bootstrap and operations repo.

## Quick Start

```bash
git clone https://github.com/rubennijhuis/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Daily Use

For normal day-to-day operation, start here:

```bash
make status       # fast "what needs attention?" snapshot
make doctor       # full health check with next steps
make ops-status   # launchd automation dashboard
make update       # compact live progress for repos, brew, runtimes, and re-stow
make spicetify-status # Spotify theming health check
```

The CLI is designed to stay compact while still showing that work is happening. Long-running commands should stream progress in a condensed dashboard style instead of going silent.

## Machine Profiles

This repo supports machine profiles so one dotfiles repo can serve multiple machine roles without becoming a giant compromise.

Available profile commands:

```bash
make profile-list
make profile-show
make profile-set PROFILE=personal-laptop
```

Current profile behavior:

- the active profile is loaded from `local/profile.env` or defaults to `personal-laptop`
- `make stow` only applies the packages allowed by the active profile
- `make doctor` shows the active profile in its overview
- `make doctor --section profile` validates profile-specific required commands, paths, and keychain items
- `make install`, `make brew-audit`, and `make brew-sync` use the active profile's Brewfiles
- `make automation-setup` installs the active profile's automation set
- `make ops-status` shows which profile the automation dashboard reflects

Tracked profile definitions live in `profiles/`.
Machine-local profile selection lives in `local/profile.env`.

## Common Commands

```bash
make help             # show all commands
make install          # full machine bootstrap
make bootstrap-verify # strict bootstrap reliability checks
make doctor           # full health checks
make ops-status       # consolidated automation + ops status
make update           # package/runtime update + restow
make maint-check      # lint + script tests
make docs-sync        # fail if generated CLI docs are stale
```

## Documentation

- Architecture and conventions: `docs/architecture.md`
- Machine profiles: `docs/machine-profiles.md`
- Runbooks: `docs/runbooks/`
- Generated command reference: `docs/reference/cli.md`
- Launchd templates and contracts: `launchd/README.md`

## Core Layout

```text
dotfiles/
├── config/          # GNU Stow packages (symlinked into $HOME)
├── setup/           # Setup scripts (stow, macos-defaults, key gen)
├── ops/             # Operations (update, clean, backup, brew, automation)
├── health/          # Diagnostics (doctor, checks, info scripts)
├── tests/           # Script behavior tests
├── lib/             # Shared shell libraries
├── hooks/           # Git hooks (pre-commit, commit-msg, pre-push)
├── launchd/         # Launchd plist templates
├── brew/            # Brewfiles (cli, apps, vscode)
├── local/           # Machine-specific config (gitignored)
├── docs/            # Architecture, runbooks, reference
├── install.sh       # Bootstrap installer
└── Makefile         # Operator entrypoint
```
