# Doctor Guide

Operational guide for `make doctor` and `make doctor-quick`.

## Commands

```bash
make doctor
make doctor-quick

# direct script usage
bash scripts/health/doctor.sh --no-color
bash scripts/health/doctor.sh --section backup --no-color
```

## What Doctor Checks

`make doctor` includes:

- Stow configuration
- SSH configuration
- GPG configuration
- Git conditional includes
- Shell configuration
- Developer directory layout
- Runtime tools (Node/Bun)
- LaunchD managed agent status
- Homebrew status
- VS Code baseline extensions
- Backup recency + automation
- Biome presence/config

`make doctor-quick` skips optional slower checks.

## Exit Codes

- `0`: all checks passed
- `1`: warnings found
- `2`: errors found

Example in scripts:

```bash
if make doctor-quick; then
  echo "healthy"
else
  echo "issues found"
fi
```

## Typical Fixes

### SSH

```bash
make ssh-setup
ssh-add ~/.ssh/id_ed25519_personal ~/.ssh/id_ed25519_work
```

### GPG

```bash
make gpg-setup
pkill gpg-agent
gpgconf --launch gpg-agent
```

### Stow / Shell / Git config

```bash
make stow
```

### Backup + automation

```bash
make backup
make backup-setup
make backup-status
```

### Doctor automation

```bash
make doctor-setup
make doctor-status
```

### VS Code baseline extensions

```bash
make vscode-setup
```

### Biome

```bash
brew install biome
```

## Section Checks

```bash
bash scripts/health/doctor.sh --section stow --no-color
bash scripts/health/doctor.sh --section ssh --no-color
bash scripts/health/doctor.sh --section gpg --no-color
bash scripts/health/doctor.sh --section git --no-color
bash scripts/health/doctor.sh --section shell --no-color
bash scripts/health/doctor.sh --section developer --no-color
bash scripts/health/doctor.sh --section runtime --no-color
bash scripts/health/doctor.sh --section launchd --no-color
bash scripts/health/doctor.sh --section homebrew --no-color
bash scripts/health/doctor.sh --section vscode --no-color
bash scripts/health/doctor.sh --section backup --no-color
bash scripts/health/doctor.sh --section biome --no-color
```

## Troubleshooting Doctor Itself

```bash
# debug execution
bash -x scripts/health/doctor.sh --no-color

# verify script style/lint
bash -n scripts/health/doctor.sh
shellcheck scripts/health/doctor.sh
```

## Related Docs

- `README.md`
- `docs/developer-migration.md`
- `docs/git-hooks.md`
- `docs/scripts-reference.md`
