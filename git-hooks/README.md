# Git Hooks

Automated code quality checks for the dotfiles repository.

## Installation

Install hooks automatically (recommended):
```bash
make hooks
```

Or manually:
```bash
bash git-hooks/install-hooks.sh
```

## Available Hooks

### pre-commit
Runs before each commit to validate staged files:

1. **Shell lint**: Runs `scripts/maintenance/lint-shell.sh` on staged shell files
2. **Executable permissions**: Ensures staged scripts have executable bit
   - Auto-fixes: adds `+x` permission if missing
3. **Shebang validation**: Verifies all scripts have proper shebangs
   - Expected: `#!/usr/bin/env bash` or `#!/bin/bash`
4. **Biome formatting**: Auto-formats staged `js/ts/json` files when available
5. **TODO/FIXME markers**: Warns about uncommitted TODOs (non-blocking)
   - Detects: TODO, FIXME, XXX, HACK comments

### commit-msg
Runs after writing the commit message to enforce subject style:

1. **Conventional commit header**: `type(scope): summary` or `type: summary`
   - Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
2. **Subject length limit**: first line must be 72 chars or less

### pre-push
Runs before push to validate repository safety:

1. **Shell lint**: runs `scripts/maintenance/lint-shell.sh` across repo
2. **Docs sync**: checks generated docs are up to date
3. **Brew drift**: warns on Brewfile drift
4. **Push safety checks** via `scripts/maintenance/hook-checks.sh`:
   - untracked shell files (warn)
   - large staged files >1MB (block)
   - weak commit subject (warn)
   - branch status policy (block on failures to `main/master`)

## Testing

Test the hooks without committing:
```bash
bash .git/hooks/pre-commit
bash .git/hooks/commit-msg "$(mktemp)"
bash .git/hooks/pre-push
```

## Bypassing Hooks

In emergencies only:
```bash
git commit --no-verify -m "Emergency fix"
```

**Note**: Bypassing hooks is discouraged as it can introduce bugs.

## Troubleshooting

### Hook not running
```bash
# Check if hooks are installed
ls -la .git/hooks/pre-commit .git/hooks/commit-msg .git/hooks/pre-push

# Reinstall hooks
make hooks
```

### Shellcheck errors
```bash
# Install shellcheck
brew install shellcheck

# Run manually on a script
shellcheck scripts/some-script.sh
```

### Hook failing incorrectly
```bash
# Run hooks in debug mode
bash -x .git/hooks/pre-commit
bash -x .git/hooks/pre-push
```
