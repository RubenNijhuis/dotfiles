# Git Hooks

Practical reference for the repo hooks in `git-hooks/`.

## What Runs

- `pre-commit`: validates staged shell and staged JS/TS/JSON files.
- `pre-push`: validates repository-wide shell quality and push safety checks.

## Install

```bash
make hooks
```

This links:

- `.git/hooks/pre-commit` -> `git-hooks/pre-commit`
- `.git/hooks/pre-push` -> `git-hooks/pre-push`

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

1. `shellcheck -x` on all shell scripts in repo
2. Generated docs sync via `make docs-sync`
3. Brewfile drift warning via `scripts/brew-audit.sh`
4. Warn on untracked shell scripts
5. Block large staged files (>1MB)
6. Warn on weak last commit subject
7. Branch status summary

Behavior:

- Blocks push on hard failures (shellcheck, stale generated docs, large files).
- Warnings do not block push.

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
- `git-hooks/pre-push`
- `git-hooks/install-hooks.sh`
- `scripts/brew-audit.sh`
- `biome.json`
