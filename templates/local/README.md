# Local Overrides Template

Use this directory as the source for machine-local templates.

## Files

- `machine.env.example`: non-secret local machine values.
- `keychain-required.txt.example`: required macOS Keychain service names.

## Usage

```bash
cp templates/local/machine.env.example local/machine.env
cp templates/local/keychain-required.txt.example local/keychain-required.txt
```

- Keep `local/` untracked for machine-specific data.
- Store secrets in Keychain, not in `local/` files.

Validate keychain requirements:

```bash
make keychain-check
```
