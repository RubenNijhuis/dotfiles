# Architecture

This repository is a personal development-environment hub. It shares packages
and user configuration across macOS, Linux, and WSL, with a thin macOS layer
for operating-system settings and desktop automation.

## Scope

- In scope: Nix-managed cross-platform packages and developer configuration,
  a thin macOS layer, user-owned private overrides, and macOS
  launchd automation.
- Out of scope: native Windows configuration; Windows is supported through WSL.

## Session Management

Use cmux for everyday Mac windows and panes. tmux remains available for
persistent terminal sessions and remote workflows; there is no requirement
to nest every cmux session inside tmux. Shared terminal configuration uses
Tokyo Night styling.

## Project runtimes

Project runtime requirements belong in pinned `devShell`s. The opt-in developer
profile supplies Node/pnpm for everyday maintenance, not a runtime guarantee for
every repository. Use tools such as uv inside the relevant project environment;
there is no baseline Python or mutable language-version manager.

## Lifecycle

1. On a fresh Mac, use the Nix-first `make install`, or evaluate and build the
   flake directly with `make nix-check` and `make nix-build`.
2. Apply macOS state with `make nix-switch`; use `make nix-home-switch` for a
   Linux or WSL target.
3. Keep writable application state and private overrides outside Nix. See the
   [ownership matrix](nix-ownership-matrix.md).
4. Operate machine workflows via launchd (`make *-setup`, `make doctor ARGS=--automation`).
5. Maintain with `make update` and `make maint-check`.
   The standard update refreshes flake inputs then checks and builds Nix without
   switching or pulling unrelated code projects. Use `make update ARGS=--exceptions`
   to update only explicitly selected macOS package exceptions, without changing
   the Nix lockfile. Repository pulls use `ops/update-repos.sh` separately.

The opt-in `maintenance` devShell supplies the locked test tools without
installing a machine profile: `nix develop .#maintenance --command make maint-check`.
GitHub Actions uses that same shell, not a separate Homebrew tool list.

## Directory Responsibilities

- `nix/`: shared Home Manager modules and host-specific system modules.
- `ops/`: operational interfaces (`ops/automation/` for launchd management, plus backup and maintenance scripts).
- `setup/`: bootstrap and provisioning scripts.
- `health/`: health check and profiling scripts.
- `lib/`: shared shell libraries.
- `tests/`: script tests.
- `launchd/`: managed launch agents and launchd contracts.
- `local/`: machine-local, untracked override templates.
- `profiles/`: transition-time machine profile definitions and launchd selection.
- `brew/`: narrow, documented macOS exceptions; Nix is the package owner by
  default.
- `docs/runbooks/`: operational procedures.

## Machine Profiles

Profiles allow the repo to adapt to different machine roles without duplicating the whole setup.

- Profile definitions live in `profiles/*.env`.
- The active profile is selected per machine via `local/profile.env`.
- If no local profile is set, the default is `personal-laptop`.

Profile behavior:

- Nix host imports select reproducible capabilities. The active shell profile
  controls documented Homebrew exceptions and automation selection only.
- `health/doctor.sh` shows the active profile in the overview section.

Profiles remain simple shell env files so they stay readable and shell-native.
They select only documented Homebrew exceptions and launchd automation; machine
readiness and secret checks stay local and optional.

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
4. Update the relevant hand-written documentation when a user-facing workflow changes.
5. For automation: add launchd template + manager compatibility + the doctor automation dashboard (`make doctor ARGS=--automation`).
6. Validate with `make maint-check` and `make bootstrap-verify`.
