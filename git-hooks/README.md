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
Runs before each commit to validate shell scripts:

1. **Shellcheck validation**: Lints all bash scripts for common errors
   - Requires: `brew install shellcheck`
   - Catches: undefined variables, syntax errors, bad practices

2. **Executable permissions**: Ensures scripts have the executable bit set
   - Auto-fixes: adds `+x` permission if missing

3. **Shebang validation**: Verifies all scripts have proper shebangs
   - Expected: `#!/usr/bin/env bash` or `#!/bin/bash`

4. **TODO/FIXME markers**: Warns about uncommitted TODOs (non-blocking)
   - Detects: TODO, FIXME, XXX, HACK comments

## Testing

Test the hooks without committing:
```bash
# Stage a script
git add scripts/some-script.sh

# Run pre-commit manually
.git/hooks/pre-commit
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
# Check if hook is installed
ls -la .git/hooks/pre-commit

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
# Check hook output
git commit -m "Test"

# Run hook in debug mode
bash -x .git/hooks/pre-commit
```
