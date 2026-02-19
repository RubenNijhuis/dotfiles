# Dotfiles

macOS-first personal/work laptop bootstrap and operations repo.

## Quick Start

```bash
git clone https://github.com/<user>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Common Commands

```bash
make help             # common command list
make install          # full machine bootstrap
make bootstrap-verify # strict bootstrap reliability checks
make doctor           # full health checks
make doctor-quick     # fast health checks
make ops-status       # consolidated automation + ops status
make update           # package/runtime update + restow
make maint-check      # lint + script tests
make docs-sync        # fail if generated CLI docs are stale
```

## Documentation

- Architecture and conventions: `docs/architecture.md`
- Runbooks: `docs/runbooks/`
- Generated command reference: `docs/reference/cli.md`
- Launchd templates and contracts: `templates/launchd/README.md`

## Core Layout

```text
dotfiles/
├── stow/            # GNU Stow packages
├── scripts/         # domain-organized scripts (automation/bootstrap/health/...)
├── templates/       # launchd, ssh, gpg, local templates
├── brew/            # profile-separated Brewfiles
├── docs/            # architecture, runbooks, reference
├── macos/           # macOS defaults
├── install.sh       # bootstrap installer
└── Makefile         # operator entrypoint
```
