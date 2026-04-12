# Machine Profiles

Machine profiles let one dotfiles repo support multiple machine roles without forcing every machine to use the same config surface.

## What A Profile Is

A profile is a tracked shell env file in `profiles/` that describes how this repo should behave for a machine role.

Examples:

- `personal-laptop`
- `work-laptop`
- `minimal`

The active profile is selected locally per machine in `local/profile.env`.

If no local profile is set, the repo defaults to `personal-laptop`.

## Commands

List available profiles:

```bash
make profile-list
```

Show the active profile:

```bash
make profile-show
```

Set the active profile:

```bash
make profile-set PROFILE=personal-laptop
make profile-set PROFILE=work-laptop
make profile-set PROFILE=minimal
```

## Current Behavior In V1

Profiles currently affect:

- `make stow`
- `make doctor` overview

That means:

- `setup/stow-all.sh` only applies packages listed in the active profile
- `health/doctor.sh` shows which profile is active

Profiles do not yet control Brew, launchd automation selection, or install-time branching. Those are good next steps, but they are not part of v1.

## File Layout

Tracked profile definitions:

```text
profiles/
  personal-laptop.env
  work-laptop.env
  minimal.env
```

Machine-local selection:

```text
local/profile.env
```

Example:

```bash
DOTFILES_PROFILE="personal-laptop"
```

## Profile Definition Format

Each profile is a shell env file.

Current keys:

- `DOTFILES_PROFILE`
- `DOTFILES_PROFILE_LABEL`
- `DOTFILES_PROFILE_STOW_PACKAGES`

Example:

```bash
DOTFILES_PROFILE="minimal"
DOTFILES_PROFILE_LABEL="Minimal"
DOTFILES_PROFILE_STOW_PACKAGES="bash bat eza git hushlogin ripgrep shell ssh starship tmux zsh"
```

## Creating A New Profile

1. Copy an existing profile in `profiles/`.
2. Rename it to something meaningful like `travel-laptop.env`.
3. Adjust `DOTFILES_PROFILE_LABEL`.
4. Trim or expand `DOTFILES_PROFILE_STOW_PACKAGES`.
5. Activate it locally with:

```bash
make profile-set PROFILE=travel-laptop
```

## Recommended Workflow

For a new machine:

```bash
cp local/profile.env.example local/profile.env
make profile-set PROFILE=personal-laptop
make profile-show
make stow
make doctor
```

For switching an existing machine to another role:

```bash
make profile-set PROFILE=minimal
make stow
make doctor
```

## Design Notes

Profiles are kept as simple shell env files on purpose:

- they are easy to source from existing scripts
- they fit the shell-native architecture of the repo
- they are easy to extend later for Brew, launchd, install, and readiness workflows
