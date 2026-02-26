# Architecture

This repository is a strict, macOS-only operations hub for machine bootstrap, dotfile management, and recurring laptop automation.

## Scope

- In scope: macOS bootstrap, stow-managed config, launchd automation, developer environment reliability.
- Out of scope: Linux portability and cross-platform abstractions.

## Lifecycle

1. Bootstrap with `install.sh`.
2. Apply/stabilize config with `make stow`, `make doctor`, `make bootstrap-verify`.
3. Operate machine workflows via launchd (`make *-setup`, `make ops-status`).
4. Maintain with `make maint-check`, `make docs-sync`, `make update`.

## Directory Responsibilities

- `stow/`: source-of-truth user config packages symlinked into `$HOME`.
- `scripts/`: operational interfaces grouped by domain (`automation/`, `bootstrap/`, `health/`, `maintenance/`, `migration/`, `backup/`, `info/`, `docs/`), plus `lib/` and `tests/`.
- `templates/launchd/`: managed launch agents and launchd contracts.
- `templates/local/`: machine-local, untracked override templates.
- `brew/`: package declarations split by profile (`common`, `personal`, `work`).
- `docs/runbooks/`: operational procedures.
- `docs/reference/`: generated or canonical references.

## Script Interface Contract

All operational scripts in `scripts/**` (excluding `scripts/lib/` and `scripts/tests/`) must:

- support `--help` and return exit code `0`.
- reject unknown flags with non-zero exit and usage output.
- accept `--no-color` when they use shared output formatting.

Exception: launchd-internal scripts may be exempt only when explicitly marked with:

```bash
# SCRIPT_VISIBILITY: launchd-internal
```

## Launchd Contract

Each managed `templates/launchd/com.user.<name>.plist` must include:

- `Label`: `com.user.<name>`
- `ProgramArguments`: absolute script path (rendered from `__DOTFILES__`)
- `StandardOutPath`: `__HOME__/.local/log/<name>.out.log` (or documented variant)
- `StandardErrorPath`: `__HOME__/.local/log/<name>.err.log` (or documented variant)
- deterministic schedule (`RunAtLoad`, `StartCalendarInterval`, or `StartInterval`)

Install/uninstall/status is handled only via `scripts/automation/launchd-manager.sh`.

## Secrets and Local State

- Secrets: macOS Keychain entries (checked by `scripts/bootstrap/check-keychain.sh`).
- Non-secret machine values: local untracked files under `local/`.
- Local templates live in `templates/local/`.

## Add-New-Capability Checklist

1. Define scope and owner in docs.
2. Add/extend script with contract-compliant CLI flags.
3. Add tests under `scripts/tests/` for parsing and behavior.
4. Update or generate docs (`make docs-generate` + `make docs-sync`).
5. For automation: add launchd template + manager compatibility + `ops-status` visibility.
6. Validate with `make maint-check` and `make bootstrap-verify`.
