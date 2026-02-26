# Git Hooks

Practical reference for the repo hooks in `git-hooks/`.

## What Runs

- `pre-commit`: validates staged shell and staged JS/TS/JSON files.
- `commit-msg`: validates commit subject style.
- `pre-push`: validates repository-wide shell quality and push safety checks.

## Install

```bash
make hooks
```

This links:

- `.git/hooks/pre-commit` -> `git-hooks/pre-commit`
- `.git/hooks/commit-msg` -> `git-hooks/commit-msg`
- `.git/hooks/pre-push` -> `git-hooks/pre-push`

Only executable hook entrypoints are linked; docs/assets in `git-hooks/` are ignored.

## Pre-commit

Checks:

1. `shellcheck -x` on staged `*.sh` / `*.bash`
2. Auto-fix missing executable bit (`chmod +x`, re-stage)
3. Shebang validation (`#!/usr/bin/env bash` or `#!/bin/bash`)
4. Biome format pass on staged `*.js *.jsx *.ts *.tsx *.json *.jsonc`
5. Warn-only TODO/FIXME markers in staged shell files

Behavior:

- Fails commit on shellcheck/shebang errors.
- Auto-fixes executable-bit and Biome formatting, then re-stages.
- If Biome is not installed, formatting check is skipped with warning.

## Pre-push

Checks:

1. `scripts/maintenance/lint-shell.sh` on all shell scripts in repo (`bash -n` + `shellcheck`)
2. Generated docs sync via `make docs-sync`
3. Brewfile drift warning via `scripts/maintenance/brew-audit.sh`
4. Warn on untracked shell scripts (`scripts/maintenance/hook-checks.sh`)
5. Block large staged files (>1MB) (`scripts/maintenance/hook-checks.sh`)
6. Warn on weak last commit subject (`scripts/maintenance/hook-checks.sh`)
7. Branch status summary (`scripts/maintenance/hook-checks.sh`)

Behavior:

- Blocks push on hard failures (shellcheck, stale generated docs, large files).
- Warnings do not block push.

## Commit-msg

Checks:

1. Conventional commit subject format: `type(scope): summary` or `type: summary`
2. Subject length <= 72 characters

Allowed types:

- `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

Behavior:

- Blocks commit when the subject format is invalid or too long.

## Common Commands

```bash
# Run hooks manually
bash git-hooks/pre-commit
bash git-hooks/pre-push

# Bypass once (emergency only)
git commit --no-verify -m "..."
git push --no-verify
```

## Troubleshooting

### Hook not running

```bash
make hooks
ls -l .git/hooks/pre-commit .git/hooks/pre-push
```

Also verify commit-msg:
```bash
ls -l .git/hooks/commit-msg
```

### shellcheck missing

```bash
brew install shellcheck
```

### Biome missing

```bash
brew install biome
```

### Hook sees no staged changes

```bash
git add -A
git status --short
```

## Related Files

- `git-hooks/pre-commit`
- `git-hooks/commit-msg`
- `git-hooks/pre-push`
- `git-hooks/install-hooks.sh`
- `scripts/maintenance/brew-audit.sh`
- `scripts/maintenance/lint-shell.sh`
- `scripts/maintenance/hook-checks.sh`
- `biome.json`
