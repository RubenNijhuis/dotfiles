# Architecture

This repository is a strict, macOS-only operations hub for machine bootstrap, dotfile management, and recurring laptop automation.

## Scope

- In scope: macOS bootstrap, stow-managed config, launchd automation, developer environment reliability.
- Out of scope: Linux portability and cross-platform abstractions.

## Session Management

tmux is the session manager. Ghostty handles terminal windowing; tmux handles session persistence, pane splits, and remote workflows. The tmux config uses Tokyo Night theming consistent with the rest of the stack.

## Python

uv is the Python package and project manager. It also manages Python versions (`uv python install 3.x`). No separate version manager (pyenv, asdf) is needed. Pyright provides type checking in Neovim with `basic` mode.

## Lifecycle

1. Bootstrap with `install.sh`.
2. Select a machine profile with `make profile-set PROFILE=<name>` when needed.
3. Apply/stabilize config with `make stow`, `make doctor`, `make bootstrap-verify`.
4. Operate machine workflows via launchd (`make *-setup`, `make ops-status`).
5. Maintain with `make maint-check`, `make docs-sync`, `make update`.

## Directory Responsibilities

- `config/`: source-of-truth user config packages symlinked into `$HOME`.
- `ops/`: operational interfaces (`ops/automation/` for launchd management, plus backup and maintenance scripts).
- `setup/`: bootstrap and provisioning scripts.
- `health/`: health check and profiling scripts.
- `lib/`: shared shell libraries.
- `tests/`: script tests.
- `launchd/`: managed launch agents and launchd contracts.
- `local/`: machine-local, untracked override templates.
- `profiles/`: tracked machine profile definitions (stow selection, future profile-aware behavior).
- `brew/`: package declarations (`cli`, `apps`, `vscode`).
- `docs/runbooks/`: operational procedures.
- `docs/reference/`: generated or canonical references.

## Machine Profiles

Profiles allow the repo to adapt to different machine roles without duplicating the whole setup.

- Profile definitions live in `profiles/*.env`.
- The active profile is selected per machine via `local/profile.env`.
- If no local profile is set, the default is `personal-laptop`.

Current v1 behavior:

- `setup/stow-all.sh` only stows packages listed by the active profile.
- `health/doctor.sh` shows the active profile in the overview section.

Profiles are intentionally simple shell env files so they stay readable and easy to extend into profile-aware Brew, launchd, and install flows later.

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
5. For automation: add launchd template + manager compatibility + `ops-status` visibility.
6. Validate with `make maint-check` and `make bootstrap-verify`.
