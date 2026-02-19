# CLI Reference

Generated from live `--help` output. Do not edit manually; run `make docs-generate`.

## `install.sh`

```text
Usage: install.sh [options]

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

## `scripts/automation/launchd-manager.sh`

```text
Usage: scripts/automation/launchd-manager.sh [--help] [--no-color] <command> [agent-name]

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
  scripts/automation/launchd-manager.sh install dotfiles-backup
  scripts/automation/launchd-manager.sh install-all
  scripts/automation/launchd-manager.sh status
  scripts/automation/launchd-manager.sh restart dotfiles-doctor
```

## `scripts/automation/ops-status.sh`

```text
Usage: scripts/automation/ops-status.sh [--help] [--no-color]

Show launchd automation health, recent logs, and recent backup activity.
```

## `scripts/automation/repo-update-notify.sh`

```text
Usage: scripts/automation/repo-update-notify.sh [--help] [--no-color] [--dry-run] [path]

Wrapper around scripts/maintenance/update-repos.sh with notification and summary log.
```

## `scripts/automation/setup-automation.sh`

```text
Usage: scripts/automation/setup-automation.sh [--help] [--no-color] <backup|doctor|repo-update|ai-startup>

Examples:
  scripts/automation/setup-automation.sh backup
  scripts/automation/setup-automation.sh doctor
  scripts/automation/setup-automation.sh repo-update
  scripts/automation/setup-automation.sh ai-startup
```

## `scripts/automation/startup-ai-services.sh`

```text
Usage: scripts/automation/startup-ai-services.sh [--help] [--no-color] [--yes] [--policy <prompt|both|openclaw|lmstudio|skip>]

Prompt at login to start OpenClaw and/or LM Studio.

Options:
  --yes                       Non-interactive mode (uses --policy).
  --policy <value>            Startup mode, defaults to env AI_STARTUP_POLICY or prompt.
```

## `scripts/automation/sync-obsidian.sh`

```text
Usage: scripts/automation/sync-obsidian.sh [--help] [--no-color] [path]

Sync an Obsidian git repository (default: ~/Developer/personal/projects/obsidian-store).
```

## `scripts/backup/backup-dotfiles.sh`

```text
Usage: scripts/backup/backup-dotfiles.sh [--help] [--no-color]

Create a timestamped backup of local dotfile files before stow operations.
```

## `scripts/backup/restore-backup.sh`

```text
Usage: scripts/backup/restore-backup.sh [--help] [--no-color] [--dry-run]

Restore files from the latest backup recorded in ~/.dotfiles-backup/latest.
```

## `scripts/bootstrap/bootstrap-verify.sh`

```text
Usage: scripts/bootstrap/bootstrap-verify.sh [--help] [--no-color] [--profile <personal|work>] [--skip-doctor]

Runs bootstrap verification:
  1. install.sh dry-run
  2. script CLI tests
  3. docs sync check
  4. quick doctor check
```

## `scripts/bootstrap/check-keychain.sh`

```text
Usage: scripts/bootstrap/check-keychain.sh [--help] [--no-color] [--config <path>]

Validate required keychain items listed one service name per line.
Default config: local/keychain-required.txt
```

## `scripts/bootstrap/stow-all.sh`

```text
Usage: scripts/bootstrap/stow-all.sh [--help] [--no-color]

Stow all packages from stow/ into $HOME.
```

## `scripts/bootstrap/stow-report.sh`

```text
Usage: scripts/bootstrap/stow-report.sh [--help] [--no-color]

Preview stow operations and report package conflicts.
```

## `scripts/bootstrap/unstow-all.sh`

```text
Usage: scripts/bootstrap/unstow-all.sh [--help] [--no-color]

Unstow all packages from stow/ out of $HOME.
```

## `scripts/docs/generate-cli-reference.sh`

```text
Usage: scripts/docs/generate-cli-reference.sh [--help] [--no-color] [--check]

Generate docs/reference/cli.md from --help output.

Options:
  --check    Exit non-zero if generated output differs from committed file.
```

## `scripts/health/check-launchd-contracts.sh`

```text
Usage: scripts/health/check-launchd-contracts.sh [--help] [--no-color]

Validate templates/launchd/*.plist against repository launchd contract.
```

## `scripts/health/doctor-ci.sh`

```text
Usage: scripts/health/doctor-ci.sh [--help] [--no-color] [--profile <personal|work>]

Run deterministic CI health checks:
  1. check-scripts
  2. test-scripts
  3. launchd-check
  4. docs-sync
  5. install.sh dry-run
```

## `scripts/health/doctor-notify.sh`

```text
Usage: scripts/health/doctor-notify.sh [--help] [--no-color] [--full]

Run doctor checks and show a macOS notification when issues are found.
Defaults to quick mode; use --full for full checks.
```

## `scripts/health/doctor.sh`

```text
Usage: scripts/health/doctor.sh [--help] [--quick] [--section <name>] [--no-color]
```

## `scripts/info/gpg-info.sh`

```text
Usage: scripts/info/gpg-info.sh [--help] [--no-color]

Display GPG key and signing configuration status.
```

## `scripts/info/profile-shell.sh`

```text
Usage: scripts/info/profile-shell.sh [--help] [--no-color] [--analyze]

Without flags, generates shell profile data.
With --analyze, reads /tmp/zsh-profile.log and prints analysis.
```

## `scripts/info/ssh-info.sh`

```text
Usage: scripts/info/ssh-info.sh [--help] [--no-color]

Display SSH key, agent, and config status.
```

## `scripts/maintenance/brew-audit.sh`

```text
Usage: scripts/maintenance/brew-audit.sh [--help] [--no-color] [--check]

Audit Brewfiles against currently installed formulae, casks, and VS Code extensions.

Options:
  --check   Exit non-zero when drift is found.
```

## `scripts/maintenance/format-all.sh`

```text
Usage: scripts/maintenance/format-all.sh [--help] [--no-color]

Apply EditorConfig-style cleanup and Biome formatting across the repository.
```

## `scripts/maintenance/sync-brew.sh`

```text
Usage: scripts/maintenance/sync-brew.sh [--help] [--no-color] [--dry-run]

Sync manually installed Homebrew packages into tracked Brewfiles.
```

## `scripts/maintenance/update-repos.sh`

```text
Usage: scripts/maintenance/update-repos.sh [--help] [--no-color] [--dry-run] [path]

Update all git repositories under the provided path (default: ~/Developer).
```

## `scripts/maintenance/update.sh`

```text
Usage: scripts/maintenance/update.sh [--help] [--no-color]

Update Homebrew packages, runtime tools, and restow configs.
```

## `scripts/migration/migrate-developer-structure.sh`

```text
Usage: scripts/migration/migrate-developer-structure.sh [options]

Options:
  --dry-run                          Preview planned moves without changing files
  --complete                         Interactive categorization mode for existing setups
  --source <path>                    Source root containing repositories
                                     (default: /Users/rubennijhuis/Developer/repositories)
  --target <path>                    Target developer root
                                     (default: /Users/rubennijhuis/Developer)
  --rules <path>                     Optional pattern rules file
                                     (default: local/migration-rules.txt if present)
  --default-destination <subpath>    Fallback target subpath for unmapped repos
                                     (default: personal/projects)
  --non-interactive                  Disable prompts (auto/rules only)
  --help                             Show this help message
  --no-color                         Disable color output

Rules file format:
  pattern|destination-subpath

Example:
  # Move all repos in a legacy Work folder under work/projects
  Work/*|work/projects
```

## `scripts/migration/migrate-ssh-keys.sh`

```text
Usage: scripts/migration/migrate-ssh-keys.sh [--help] [--no-color]

Rename ~/.ssh/id_ed25519 to ~/.ssh/id_ed25519_personal.
```

## `scripts/migration/validate-repos.sh`

```text
Usage: scripts/migration/validate-repos.sh [--help] [--no-color] [path]

Validate git repositories for uncommitted, unpushed, or stashed work.
Defaults to: $HOME/Developer
```

