# Machine Profiles

Machine profiles let one dotfiles repo target multiple machine roles without
forcing each one to use the same Brewfile + automation set. The profile
system was slimmed when the repo moved from stow to chezmoi: chezmoi handles
config-file variance via templates, so the profile is now only responsible
for **which package list installs** and **which launchd agents register**.

## What A Profile Is

A profile is a tracked shell env file in `profiles/` describing how this
repo should behave for a machine role.

Tracked profiles:

- `personal-laptop`
- `work-laptop`
- `minimal`

The active profile is selected locally per machine in `local/profile.env`.
If none is set, the repo defaults to `personal-laptop`.

## Commands

```bash
make profile-list                # list available profiles
make profile-show                # show the active profile
make profile-set PROFILE=name    # set the active profile (writes local/profile.env)
```

## Current Behavior

Profiles currently affect:

- `make install` — Brewfile selection follows the active profile
- `make brew-audit` / `make brew-sync` — audit against the profile's Brewfiles
- `make automation-setup` — installs the profile's selected launchd agents
- `make doctor` — overview shows the active profile

Config files (zshrc, gitconfig, ssh, …) are managed by chezmoi and do **not**
vary per profile today — chezmoi templates handle machine variance through
`~/.config/chezmoi/chezmoi.toml` data instead.

## File Layout

```text
profiles/
  personal-laptop.env
  work-laptop.env
  minimal.env

local/profile.env       # machine-local selection (gitignored)
```

`local/profile.env` example:

```bash
DOTFILES_PROFILE="personal-laptop"
```

## Profile Definition Format

Each profile is a shell env file with two relevant keys:

- `DOTFILES_PROFILE` — canonical name (must match filename without `.env`)
- `DOTFILES_PROFILE_LABEL` — human-readable
- `DOTFILES_PROFILE_BREWFILES` — space-separated list of `Brewfile.*` to apply
- `DOTFILES_PROFILE_AUTOMATIONS` — space-separated list of launchd agent names

Example (`profiles/minimal.env`):

```bash
DOTFILES_PROFILE="minimal"
DOTFILES_PROFILE_LABEL="Minimal"
DOTFILES_PROFILE_BREWFILES="Brewfile.cli"
DOTFILES_PROFILE_AUTOMATIONS="dotfiles-backup dotfiles-doctor log-cleanup brew-audit weekly-digest"
```

## Creating A New Profile

1. Copy an existing profile in `profiles/`.
2. Rename to something meaningful (`travel-laptop.env`).
3. Adjust `DOTFILES_PROFILE`, `DOTFILES_PROFILE_LABEL`.
4. Choose Brewfiles via `DOTFILES_PROFILE_BREWFILES`.
5. Choose automations via `DOTFILES_PROFILE_AUTOMATIONS` (see
   `ops/automation/agents.manifest` for valid agent names).
6. Activate:

   ```bash
   make profile-set PROFILE=travel-laptop
   ```

## New Machine Workflow

```bash
cp local/profile.env.example local/profile.env
make profile-set PROFILE=personal-laptop
make install            # bootstrap + brew + chezmoi apply + macos
make doctor             # health + automation dashboard
```

## Design Notes

The profile system used to also declare "required commands / paths /
keychain items" as a machine-readiness contract. Those checks have been
removed — chezmoi templates conditionally apply config based on tool
availability, and the individual doctor checks (`check_ssh`,
`check_developer`, etc.) already validate the paths that matter.
