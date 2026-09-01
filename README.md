# Dotfiles

Nix-first, cross-platform personal environment with a thin macOS layer.

## Quick Start

### Prerequisites

Before running `install.sh`:

1. Update macOS to the latest release (System Settings > General > Software Update). Homebrew tracks Apple's latest and refuses source builds on older SDKs.
2. Refresh Xcode Command Line Tools:
   ```bash
   sudo rm -rf /Library/Developer/CommandLineTools
   sudo xcode-select --install
   ```
   Wait for the GUI installer to finish before continuing.

### Install

```bash
git clone https://github.com/rubennijhuis/dotfiles.git ~/Developer/personal/dotfiles
cd ~/Developer/personal/dotfiles
./install.sh
```

`install.sh` retains the legacy macOS bootstrap path. The reproducible source of
truth is the flake: inspect it with `make nix-check` and `make nix-build`, then
apply it on macOS with `make nix-switch`.

## Daily Use

For normal day-to-day operation, start here:

```bash
make doctor       # default: quick summary + automation dashboard
make doctor --full  # full health check with all sections
make doctor --automation   # launchd automation dashboard
make nix-check    # evaluate all declared Nix targets
make nix-build    # build the macOS configuration without changing the system
make nix-switch   # apply the macOS configuration
make update       # update the remaining transition tooling and local state
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
- Nix/Home Manager owns the shared core; ChezMoi only materializes the few
  paths still explicitly marked transition-owned
- `make doctor` shows the active profile in its overview
- `make install`, `make brew-audit`, and `make brew-sync` use the active profile's Brewfiles
- `make automation-setup` installs the active profile's automation set
- `make doctor --automation` shows which profile the automation dashboard reflects

Tracked profile definitions live in `profiles/`.
Machine-local profile selection lives in `local/profile.env`.

## Common Commands

```bash
make help             # show all commands
make install          # bootstrap the transition tooling on a new Mac
make nix-check        # evaluate every supported target
make nix-build        # build the current macOS target
make nix-switch       # apply the current macOS target
make bootstrap-verify # strict bootstrap reliability checks
make doctor           # full health checks
make doctor --automation       # consolidated automation + ops status
make update           # package/runtime update + chezmoi apply
make maint-check      # lint + script tests
make docs-sync        # fail if generated CLI docs are stale
```

## Documentation

- Architecture and conventions: `docs/architecture.md`
- Everyday assistant and application preferences: `docs/personal-application-policy.md`
- Machine profiles: `docs/machine-profiles.md`
- Runbooks: `docs/runbooks/`
- Generated command reference: `docs/reference/cli.md`
- Launchd templates and contracts: `launchd/README.md`

## Core Layout

```text
dotfiles/
├── chezmoi/         # Current home configuration source state
├── nix/             # Cross-platform Home Manager and macOS nix-darwin modules
├── setup/           # Setup scripts (key gen, vscode extensions, bloatware removal)
├── ops/             # Operations (update, clean, backup, brew, automation)
├── health/          # Diagnostics (doctor, checks, info scripts)
├── tests/           # Script behavior tests
├── lib/             # Shared shell libraries
├── hooks/           # Git hooks (pre-commit, commit-msg, pre-push)
├── launchd/         # Launchd plist templates
├── brew/            # Lean bootstrap plus legacy application inventories
├── local/           # Machine-specific config (gitignored)
├── docs/            # Architecture, runbooks, reference
├── install.sh       # Bootstrap installer
└── Makefile         # Operator entrypoint
```
