# Git Hooks

Hooks live in `hooks/` and are symlinked into `.git/hooks/` via `make hooks`.

## pre-commit

Runs on staged files only:

1. `shellcheck -x` on staged shell scripts
2. Auto-fix missing executable bit on `.sh` files (re-stages)
3. Shebang validation (`#!/usr/bin/env bash`)
4. Biome format on staged JS/TS/JSON (auto-fixes and re-stages)
5. Secret detection (AWS keys, GitHub tokens, etc.) — blocks commit
6. Warn-only TODO/FIXME markers

## commit-msg

1. Conventional commit format: `type(scope): summary` or `type: summary`
2. Subject length <= 72 characters

## pre-push

1. Brewfile drift check (warning only)
2. Generated docs sync — blocks push if stale
3. Untracked shell scripts warning
4. Large file detection (>1MB) — blocks push
5. Commit message quality check
6. Branch status — blocks push to main with failures

## Bypass

```bash
git commit --no-verify  # skip pre-commit + commit-msg
git push --no-verify    # skip pre-push
```
