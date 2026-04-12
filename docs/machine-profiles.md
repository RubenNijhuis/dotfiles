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

## Current Behavior

Profiles currently affect:

- `make stow`
- `make doctor` overview
- `make doctor --section profile`
- `make install`
- `make brew-audit`
- `make brew-sync`
- `make automation-setup`
- `make ops-status`

That means:

- `setup/stow-all.sh` only applies packages listed in the active profile
- `health/doctor.sh` shows which profile is active
- `health/doctor.sh --section profile` validates that the active machine satisfies that profile's declared contract
- install-time Brew bundle selection follows the active profile's Brewfile list
- Brew audit/sync report against the active profile's Brewfiles
- `automation-setup` installs the profile's selected LaunchD agents
- `ops-status` shows which profile the dashboard reflects

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
- `DOTFILES_PROFILE_BREWFILES`
- `DOTFILES_PROFILE_AUTOMATIONS`
- `DOTFILES_PROFILE_REQUIRED_COMMANDS`
- `DOTFILES_PROFILE_REQUIRED_PATHS`
- `DOTFILES_PROFILE_REQUIRED_KEYCHAIN_ITEMS`

Example:

```bash
DOTFILES_PROFILE="minimal"
DOTFILES_PROFILE_LABEL="Minimal"
DOTFILES_PROFILE_STOW_PACKAGES="bash bat eza git hushlogin ripgrep shell ssh starship tmux zsh"
DOTFILES_PROFILE_BREWFILES="Brewfile.cli"
DOTFILES_PROFILE_AUTOMATIONS="dotfiles-backup dotfiles-doctor log-cleanup brew-audit weekly-digest"
DOTFILES_PROFILE_REQUIRED_COMMANDS="git"
DOTFILES_PROFILE_REQUIRED_PATHS="$DOTFILES_DEVELOPER_ROOT::Developer root|$HOME/.ssh/id_ed25519_personal::Personal SSH key"
```

## Profile Contract Keys

These keys let a profile declare what "healthy" means for that machine role.

- `DOTFILES_PROFILE_REQUIRED_COMMANDS`
  Space-separated commands that must be available on `PATH`.
- `DOTFILES_PROFILE_REQUIRED_PATHS`
  Pipe-separated `path::label` entries that must exist on disk.
- `DOTFILES_PROFILE_REQUIRED_KEYCHAIN_ITEMS`
  Pipe-separated `service::label` entries that must exist in the macOS Keychain.

Example:

```bash
DOTFILES_PROFILE_REQUIRED_COMMANDS="git brew tmux code"
DOTFILES_PROFILE_REQUIRED_PATHS="$DOTFILES_DEVELOPER_ROOT::Developer root|$DOTFILES_OBSIDIAN_REPO_PATH::Obsidian vault"
DOTFILES_PROFILE_REQUIRED_KEYCHAIN_ITEMS="github.com::GitHub token|openai-api::OpenAI API key"
```

## Creating A New Profile

1. Copy an existing profile in `profiles/`.
2. Rename it to something meaningful like `travel-laptop.env`.
3. Adjust `DOTFILES_PROFILE_LABEL`.
4. Trim or expand `DOTFILES_PROFILE_STOW_PACKAGES`.
5. Choose the Brewfiles to apply via `DOTFILES_PROFILE_BREWFILES`.
6. Choose the automations to install via `DOTFILES_PROFILE_AUTOMATIONS`.
7. Activate it locally with:

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
