# Local Overrides Template

Use this directory as the source for machine-local templates.

## Files

- `machine.env.example`: non-secret local machine values.
- `profile.env.example`: active tracked profile selection for this machine.
- `keychain-required.txt.example`: required macOS Keychain service names.
## Usage

```bash
cp local/machine.env.example local/machine.env
cp local/profile.env.example local/profile.env
cp local/keychain-required.txt.example local/keychain-required.txt
```

Set the active profile for this machine:

```bash
make profile-set PROFILE=personal-laptop
make profile-show
```

- Keep `local/` untracked for machine-specific data.
- Store secrets in Keychain, not in `local/` files.
- Keep profile selection in `local/profile.env`; keep profile definitions in tracked `profiles/`.

Validate keychain requirements:

```bash
make keychain-check
```
