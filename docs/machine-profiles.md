# Machine Profiles

Machine profiles let one dotfiles repo target multiple machine roles without
forcing each one to use the same Brewfile + automation set. The profile
system selects only **documented Homebrew exceptions** and **launchd agents**.
Nix host imports select declarative configuration and capability profiles.

> The long-term, cross-platform capability model is in
> [the Nix transition](nix-transition.md#capability-profiles). These legacy
> profiles are transition-only: `minimal` has no Homebrew dependencies, while
> portable tools belong in the shared Nix core. They do not
> install every desktop application on a new laptop.

## What A Profile Is

A profile is a tracked shell env file in `profiles/` describing how this
repo should behave for a machine role.

Tracked profiles:

- `personal-laptop`
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
- `make brew-audit` — audit the profile's explicit Homebrew exceptions
- `make automation-setup` — installs the profile's selected launchd agents
- `make doctor` — overview shows the active profile

The portable core is selected by the Nix host target, not these legacy
profiles. See [Nix transition](nix-transition.md#capability-profiles) for the
cross-platform capability model. ChezMoi is retired; private overrides remain
user-owned, outside Nix and Git.

The personal-laptop profile selects only the read-only update report. Repo
pulls, backups, cleanup and local servers remain explicit opt-ins. Obsidian
uses the existing iCloud vault; these profiles do not configure another sync
transport.

This Mac's exception selection restores Prism/Java, Mac pinentry, Krita,
RawTherapee, and HandBrake. These are already installed, not a recommendation
to put creative tools on every host. `minimal` selects none. Installed packages
outside either selection remain visible in the audit, never silently adopted
or removed. The installer trusts only taps explicitly declared by that profile.

## File Layout

```text
profiles/
  personal-laptop.env
  minimal.env

local/profile.env       # machine-local selection (gitignored)
```

`local/profile.env` example:

```bash
DOTFILES_PROFILE="personal-laptop"
```

## Profile Definition Format

Each profile is a shell env file with four relevant keys:

- `DOTFILES_PROFILE` — canonical name (must match filename without `.env`)
- `DOTFILES_PROFILE_LABEL` — human-readable
- `DOTFILES_PROFILE_BREWFILES` — space-separated list of `Brewfile.*` to apply
- `DOTFILES_PROFILE_AUTOMATIONS` — space-separated launchd agent names; empty
  means none, not all. The personal laptop selects only `update-audit`.

Example (`profiles/minimal.env`):

```bash
DOTFILES_PROFILE="minimal"
DOTFILES_PROFILE_LABEL="Minimal"
DOTFILES_PROFILE_BREWFILES=""
DOTFILES_PROFILE_AUTOMATIONS=""
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
make install            # install and activate Nix, then selected Mac exceptions
make doctor             # health + automation dashboard
```

Reconnect the existing Files vault first, following the
[recovery runbook](runbooks/new-mac-recovery.md). A second `make nix-switch`
is needed only after configuration changes, not immediately after installation.

## Design Notes

The profile system used to also declare "required commands / paths /
keychain items" as a machine-readiness contract. Those checks have been
removed — Nix host imports select configurations, and the individual doctor checks (`check_ssh`,
`check_developer`, etc.) already validate the paths that matter.
