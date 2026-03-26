# Dotfiles

macOS laptop bootstrap and operations repo.

## Quick Start

```bash
git clone https://github.com/rubennijhuis/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

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
