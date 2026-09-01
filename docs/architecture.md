# Architecture

This repository is a personal development-environment hub. It shares packages
and user configuration across macOS, Linux, and WSL, with a thin macOS layer
for operating-system settings and desktop automation.

## Scope

- In scope: Nix-managed cross-platform packages and developer configuration,
  a thin macOS layer, explicitly transition-owned ChezMoi paths, and macOS
  launchd automation.
- Out of scope: native Windows configuration; Windows is supported through WSL.

## Session Management

tmux is the session manager. Ghostty handles terminal windowing; tmux handles session persistence, pane splits, and remote workflows. The tmux config uses Tokyo Night theming consistent with the rest of the stack.

## Python

uv is the Python package and project manager. It also manages Python versions (`uv python install 3.x`). No separate version manager (pyenv, asdf) is needed. Pyright provides type checking in Neovim with `basic` mode.

## Lifecycle

1. On a fresh Mac, use the Nix-first `make install`, or evaluate and build the
   flake directly with `make nix-check` and `make nix-build`.
2. Apply macOS state with `make nix-switch`; use `make nix-home-switch` for a
   Linux or WSL target.
3. Use `chezmoi apply` only for a path still marked transition-owned in the
   [ownership matrix](nix-ownership-matrix.md).
4. Operate machine workflows via launchd (`make *-setup`, `make doctor --automation`).
5. Maintain with `make update`, `make maint-check`, and `make docs-sync`.
   The standard update refreshes flake inputs then checks and builds Nix without
   switching; the broad pre-Nix routine is `make update-legacy`.

## Directory Responsibilities

- `chezmoi/`: remaining transition-owned paths; it is not the source of truth
  for new configuration.
- `nix/`: shared Home Manager modules and host-specific system modules.
- `ops/`: operational interfaces (`ops/automation/` for launchd management, plus backup and maintenance scripts).
- `setup/`: bootstrap and provisioning scripts.
- `health/`: health check and profiling scripts.
- `lib/`: shared shell libraries.
- `tests/`: script tests.
- `launchd/`: managed launch agents and launchd contracts.
- `local/`: machine-local, untracked override templates.
- `profiles/`: transition-time machine profile definitions and launchd selection.
- `brew/`: documented macOS exceptions plus historical inventories; Nix is the
  package owner by default.
- `docs/runbooks/`: operational procedures.
- `docs/reference/`: generated or canonical references.

## Machine Profiles

Profiles allow the repo to adapt to different machine roles without duplicating the whole setup.

- Profile definitions live in `profiles/*.env`.
- The active profile is selected per machine via `local/profile.env`.
- If no local profile is set, the default is `personal-laptop`.

Transition-time behavior:

- `chezmoi apply` materializes only the remaining transition-owned paths under
  `chezmoi/` into `$HOME`. It receives no new owned paths. The active profile
  controls legacy Homebrew exceptions and automation selection, not Nix
  capabilities.
- `health/doctor.sh` shows the active profile in the overview section.

Profiles remain simple shell env files so they stay readable and shell-native, but they can now also declare machine-role contracts such as required commands, paths, and keychain items.

## Script Interface Contract

All operational scripts (excluding `lib/` and `tests/`) must:

- support `--help` and return exit code `0`.
- reject unknown flags with non-zero exit and usage output.
- accept `--no-color` when they use shared output formatting.

Exception: launchd-internal scripts may be exempt only when explicitly marked with:

```bash
# SCRIPT_VISIBILITY: launchd-internal
```

## Launchd Contract

Each managed `launchd/com.user.<name>.plist` must include:

- `Label`: `com.user.<name>`
- `ProgramArguments`: absolute script path (rendered from `__DOTFILES__`)
- `StandardOutPath`: `__HOME__/.local/log/<name>.out.log` (or documented variant)
- `StandardErrorPath`: `__HOME__/.local/log/<name>.err.log` (or documented variant)
- deterministic schedule (`RunAtLoad`, `StartCalendarInterval`, or `StartInterval`)

Install/uninstall/status is handled only via `ops/automation/launchd-manager.sh`.

## Secrets and Local State

- Secrets: macOS Keychain entries (checked by `setup/check-keychain.sh`).
- Non-secret machine values: local untracked files under `local/`.
- Local templates live in `local/`.
- Active machine profile selection also lives in `local/`.

## Add-New-Capability Checklist

1. Define scope and owner in docs.
2. Add/extend script with contract-compliant CLI flags.
3. Add tests under `tests/` for parsing and behavior.
4. Update or generate docs (`bash ops/generate-cli-reference.sh` + `make docs-sync`).
5. For automation: add launchd template + manager compatibility + the doctor automation dashboard (`make doctor --automation`).
6. Validate with `make maint-check` and `make bootstrap-verify`.
