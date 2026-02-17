# CLI Reference

Generated from live `--help` output. Do not edit manually; run `make docs-generate`.

## `install.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/install.sh [options]

Options:
  --yes                         Non-interactive mode with defaults
  --dry-run                     Preview all steps without making changes
  --from-step <1-10>            Start execution from a specific step
  --profile <personal|work>     Set profile without prompting
  --with-macos-defaults         Apply macOS defaults
  --without-macos-defaults      Skip macOS defaults
  --with-ssh                    Generate SSH keys
  --without-ssh                 Skip SSH key generation
  --with-gpg                    Generate GPG key
  --without-gpg                 Skip GPG key generation
  --self-test-checkpoint        Run checkpoint/resume logic tests and exit
  --help, -h                    Show this help message
```

## `scripts/backup-dotfiles.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/backup-dotfiles.sh [--help] [--no-color]

Create a timestamped backup of local dotfile files before stow operations.
```

## `scripts/bootstrap-verify.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/bootstrap-verify.sh [--help] [--no-color] [--profile <personal|work>] [--skip-doctor]

Runs bootstrap verification:
  1. install.sh dry-run
  2. script CLI tests
  3. docs sync check
  4. quick doctor check
```

## `scripts/brew-audit.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/brew-audit.sh [--help] [--no-color]

Audit Brewfiles against currently installed formulae, casks, and VS Code extensions.
```

## `scripts/check-keychain.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/check-keychain.sh [--help] [--no-color] [--config <path>]

Validate required keychain items listed one service name per line.
Default config: local/keychain-required.txt
```

## `scripts/doctor-notify.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/doctor-notify.sh [--help] [--no-color] [--full]

Run doctor checks and show a macOS notification when issues are found.
Defaults to quick mode; use --full for full checks.
```

## `scripts/doctor.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/doctor.sh [--help] [--quick] [--section <name>] [--no-color]
```

## `scripts/format-all.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/format-all.sh [--help] [--no-color]

Apply EditorConfig-style cleanup and Biome formatting across the repository.
```

## `scripts/generate-cli-reference.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/generate-cli-reference.sh [--help] [--no-color] [--check]

Generate docs/reference/cli.md from --help output.

Options:
  --check    Exit non-zero if generated output differs from committed file.
```

## `scripts/gpg-info.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/gpg-info.sh [--help] [--no-color]

Display GPG key and signing configuration status.
```

## `scripts/launchd-manager.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/launchd-manager.sh [--help] [--no-color] <command> [agent-name]

Commands:
  install <agent>   Install and load a LaunchD agent
  install-all       Install and load all available LaunchD agents
  uninstall <agent> Unload and remove a LaunchD agent
  list              List all available agents
  status            Show status of installed agents
  restart <agent>   Restart a running agent

Available agents:
  ai-startup-selector  Prompt at login to start OpenClaw/LM Studio
  dotfiles-backup      Automated daily backups
  dotfiles-doctor      Daily health monitoring
  obsidian-sync        Obsidian vault synchronization
  repo-update          Repository updates

Examples:
  /Users/rubennijhuis/dotfiles/scripts/launchd-manager.sh install dotfiles-backup
  /Users/rubennijhuis/dotfiles/scripts/launchd-manager.sh install-all
  /Users/rubennijhuis/dotfiles/scripts/launchd-manager.sh status
  /Users/rubennijhuis/dotfiles/scripts/launchd-manager.sh restart dotfiles-doctor
```

## `scripts/migrate-developer-structure.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/migrate-developer-structure.sh [--dry-run] [--complete]

Modes:
  --dry-run   Preview standard migration plan without moving repos.
  --complete  Complete migration for remaining repos in legacy layout.
```

## `scripts/migrate-ssh-keys.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/migrate-ssh-keys.sh [--help] [--no-color]

Rename ~/.ssh/id_ed25519 to ~/.ssh/id_ed25519_personal.
```

## `scripts/ops-status.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/ops-status.sh [--help] [--no-color]

Show launchd automation health, recent logs, and recent backup activity.
```

## `scripts/profile-shell.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/profile-shell.sh [--help] [--no-color] [--analyze]

Without flags, generates shell profile data.
With --analyze, reads /tmp/zsh-profile.log and prints analysis.
```

## `scripts/repo-update-notify.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/repo-update-notify.sh [--help] [--no-color] [--dry-run] [path]

Wrapper around scripts/update-repos.sh with notification and summary log.
```

## `scripts/restore-backup.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/restore-backup.sh [--help] [--no-color] [--dry-run]

Restore files from the latest backup recorded in ~/.dotfiles-backup/latest.
```

## `scripts/setup-automation.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/setup-automation.sh [--help] [--no-color] <backup|doctor|repo-update|ai-startup>

Examples:
  /Users/rubennijhuis/dotfiles/scripts/setup-automation.sh backup
  /Users/rubennijhuis/dotfiles/scripts/setup-automation.sh doctor
  /Users/rubennijhuis/dotfiles/scripts/setup-automation.sh repo-update
  /Users/rubennijhuis/dotfiles/scripts/setup-automation.sh ai-startup
```

## `scripts/ssh-info.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/ssh-info.sh [--help] [--no-color]

Display SSH key, agent, and config status.
```

## `scripts/startup-ai-services.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/startup-ai-services.sh [--help] [--no-color] [--yes] [--policy <prompt|both|openclaw|lmstudio|skip>]

Prompt at login to start OpenClaw and/or LM Studio.

Options:
  --yes                       Non-interactive mode (uses --policy).
  --policy <value>            Startup mode, defaults to env AI_STARTUP_POLICY or prompt.
```

## `scripts/stow-all.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/stow-all.sh [--help] [--no-color]

Stow all packages from stow/ into $HOME.
```

## `scripts/stow-report.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/stow-report.sh [--help] [--no-color]

Preview stow operations and report package conflicts.
```

## `scripts/sync-brew.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/sync-brew.sh [--help] [--no-color] [--dry-run]

Sync manually installed Homebrew packages into tracked Brewfiles.
```

## `scripts/sync-obsidian.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/sync-obsidian.sh [--help] [--no-color] [path]

Sync an Obsidian git repository (default: ~/Developer/personal/projects/obsidian-store).
```

## `scripts/unstow-all.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/unstow-all.sh [--help] [--no-color]

Unstow all packages from stow/ out of $HOME.
```

## `scripts/update-repos.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/update-repos.sh [--help] [--no-color] [--dry-run] [path]

Update all git repositories under the provided path (default: ~/Developer).
```

## `scripts/update.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/update.sh [--help] [--no-color]

Update Homebrew packages, runtime tools, and restow configs.
```

## `scripts/validate-repos.sh`

```text
Usage: /Users/rubennijhuis/dotfiles/scripts/validate-repos.sh [--help] [--no-color] [path]

Validate git repositories for uncommitted, unpushed, or stashed work.
Defaults to: $HOME/Developer
```

