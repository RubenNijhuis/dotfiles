# Dotfiles

Nix-first, cross-platform personal environment with a thin macOS layer.

## Quick Start

### Prerequisites

Before the first Nix activation:

1. Update macOS to the latest release (System Settings > General > Software Update).
2. Install Xcode Command Line Tools if absent:
   ```bash
   xcode-select --install
   ```
   Wait for the GUI installer to finish. If already installed, use Software
   Update for updates; do not routinely delete the existing toolchain.

### Install

```bash
git clone https://github.com/rubennijhuis/dotfiles.git ~/Developer/personal/dotfiles
cd ~/Developer/personal/dotfiles
./install.sh
```

`install.sh` is the Nix-first bootstrap: it verifies and applies the flake,
then uses Homebrew only for the small, documented macOS exceptions that the
pinned Nix package set cannot currently provide.

## Daily Use

For normal day-to-day operation, start here:

```bash
make doctor       # default: quick summary + automation dashboard
make doctor ARGS=--full  # full health check with all sections
make doctor ARGS=--automation  # launchd automation dashboard
make nix-check-all # check the flake on all declared platforms
make nix-build    # build the macOS configuration without changing the system
make nix-switch   # apply the macOS configuration
make update       # refresh flake inputs, then check and build without switching
make spicetify-status # Spotify theming health check
make maint-check  # shell lint, tests, launchd contracts, and Brew exceptions
make bootstrap-verify # bootstrap reliability checks
make help         # complete command list
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
- Nix/Home Manager owns declarative configuration; applications and the user
  own writable/private state. ChezMoi is retired.
- `make doctor` shows the active profile in its overview
- `make install` is Nix-first; `make brew-audit` reviews the documented
  macOS exceptions. Homebrew is limited to those exceptions.
- `make automation-setup` installs only the active profile's selected jobs:
  the laptop selects the update report; the minimal profile selects none.
- `make doctor ARGS=--automation` shows which profile the automation dashboard reflects

Tracked profile definitions live in `profiles/`.
Machine-local profile selection lives in `local/profile.env`.

## Documentation

- Architecture and conventions: `docs/architecture.md`
- Everyday assistant and application preferences: `docs/personal-application-policy.md`
- Machine profiles: `docs/machine-profiles.md`
- Runbooks: `docs/runbooks/`
- Launchd templates and contracts: `launchd/README.md`

## Core Layout

```text
dotfiles/
├── nix/             # Cross-platform Home Manager and macOS nix-darwin modules
├── setup/           # Setup scripts (key generation and VS Code extensions)
├── ops/             # Operations (update, clean, backup, brew, automation)
├── health/          # Diagnostics (doctor, checks, info scripts)
├── tests/           # Script behavior tests
├── lib/             # Shared shell libraries
├── hooks/           # Git hooks (pre-commit, commit-msg, pre-push)
├── launchd/         # Launchd plist templates
├── brew/            # Documented macOS exceptions only
├── local/           # Machine-specific config (gitignored)
├── docs/            # Architecture and current runbooks
├── install.sh       # Bootstrap installer
└── Makefile         # Operator entrypoint
```
