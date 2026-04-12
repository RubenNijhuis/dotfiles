# CLI Reference

Generated from live `--help` output. Do not edit manually; run `bash ops/generate-cli-reference.sh`.

## `install.sh`

```text
Usage: install.sh [options]

Options:
  --yes                         Non-interactive mode with defaults
  --dry-run                     Preview all steps without making changes
  --from-step <1-9>             Start execution from a specific step
  --with-macos-defaults         Apply macOS defaults
  --without-macos-defaults      Skip macOS defaults
  --with-ssh                    Generate SSH keys
  --without-ssh                 Skip SSH key generation
  --with-gpg                    Generate GPG key
  --without-gpg                 Skip GPG key generation
  --with-bloatware-removal      Remove common macOS bloatware apps
  --without-bloatware-removal   Skip bloatware removal
  --no-color                    Disable colored output
  --self-test-checkpoint        Run checkpoint/resume logic tests and exit
  --help, -h                    Show this help message
```

## `health/check-launchd-contracts.sh`

```text
Usage: health/check-launchd-contracts.sh [--help] [--no-color]

Validate launchd/*.plist against repository launchd contract.
```

## `health/check-vscode-parity.sh`

```text
Usage: health/check-vscode-parity.sh [--help] [--no-color] [--check]

Verify VS Code extension parity between extensions.txt and Brewfile.vscode.

Options:
  --check     Exit non-zero if drift is detected (for CI/Makefile use)
  --no-color  Disable colored output
  --help      Show this help message
```

## `health/doctor-notify.sh`

```text
Usage: health/doctor-notify.sh [--help] [--no-color] [--full]

Run doctor checks and show a macOS notification when issues are found.
Defaults to quick mode; use --full for full checks.
```

## `health/doctor.sh`

```text
Usage: health/doctor.sh [--help] [--quick] [--full] [--status] [--section <name>] [--no-color]

Comprehensive system health check for dotfiles setup.

Options:
  --quick             Run a reduced set of checks (skip slow network/brew checks)
  --full              Run the full check set (default)
  --status            Show quick actionable system status summary
  --section <name>    Run only the specified check section
  --no-color          Disable colored output
  --help, -h          Show this help message

Sections:
  stow, ssh, gpg, git, shell, developer, runtime,
  launchd, homebrew, backup, biome, tmux, neovim, starship, shell-perf
```

## `health/gpg-info.sh`

```text
Usage: health/gpg-info.sh [--help] [--no-color]

Display GPG key and signing configuration status.
```

## `health/ssh-info.sh`

```text
Usage: health/ssh-info.sh [--help] [--no-color]

Display SSH key, agent, and config status.
```

## `ops/automation/launchd-manager.sh`

```text
Usage: ops/automation/launchd-manager.sh [--help] [--no-color] <command> [agent-name]

Commands:
  install <agent>   Install and load a LaunchD agent
  install-all       Install and load all agents
  uninstall <agent> Unload and remove a LaunchD agent
  uninstall-all     Unload and remove all agents
  list              List available agents
  status            Show status of installed agents
  restart <agent>   Restart a running agent
```

## `ops/automation/ops-status.sh`

```text
Usage: ops/automation/ops-status.sh [--help] [--no-color]

Show launchd automation health, recent logs, and recent backup activity.
```

## `ops/automation/repo-update-notify.sh`

```text
Usage: ops/automation/repo-update-notify.sh [--help] [--no-color] [--dry-run] [path]

Wrapper around ops/update-repos.sh with notification and summary log.
```

## `ops/automation/setup-automation.sh`

```text
Usage: ops/automation/setup-automation.sh [--help] [--no-color] <target>

Targets:
  backup         Setup backup automation
  doctor         Setup health monitoring
  repo-update    Setup repository updates
  obsidian-sync  Setup Obsidian vault sync
  lmstudio       Setup LM Studio server
  log-cleanup    Setup log rotation
  brew-audit     Setup Brewfile drift detection
  weekly-digest  Setup weekly digest
  setup-all      Setup all applicable automations
```

## `ops/automation/sync-obsidian.sh`

```text
Usage: ops/automation/sync-obsidian.sh [--help] [--no-color] [path]

Sync an Obsidian git repository (default: $DOTFILES_DEVELOPER_ROOT/personal/projects/obsidian-store).
```

## `ops/automation/weekly-digest.sh`

```text
Usage: ops/automation/weekly-digest.sh [--help] [--no-color]

Summarize automation health over the past 7 days and send a notification.
```

## `ops/backup-dotfiles.sh`

```text
Usage: ops/backup-dotfiles.sh [--help] [--no-color]

Back up machine-specific files not tracked by git: local overrides,
SSH keys, GPG keys, and shell local config.
```

## `ops/brew-audit.sh`

```text
Usage: ops/brew-audit.sh [--help] [--no-color] [--check]

Audit Brewfiles against currently installed formulae, casks, and VS Code extensions.

Options:
  --check   Exit non-zero when drift is found.
```

## `ops/clean-all.sh`

```text
Usage: ops/clean-all.sh [--help] [--no-color] [--dry-run]

Full cleanup: zsh cache, logs, .DS_Store, old backups, and Homebrew cache.
```

## `ops/clean.sh`

```text
Usage: ops/clean.sh [--help] [--no-color] [--dry-run] [--quiet]

Remove zsh caches, automation log files, and .DS_Store files from the repo.
```

## `ops/cleanup-logs.sh`

```text
Usage: ops/cleanup-logs.sh [--help] [--no-color] [--days N]

Delete automation log files older than N days (default: 30).
```

## `ops/format-all.sh`

```text
Usage: ops/format-all.sh [--help] [--no-color]

Run Biome formatting on JS/TS/JSON files and ensure shell scripts are executable.
EditorConfig handles whitespace, line endings, and indentation via your editor.
```

## `ops/generate-cli-reference.sh`

```text
Usage: ops/generate-cli-reference.sh [--help] [--no-color] [--check]

Generate docs/reference/cli.md from --help output.

Options:
  --check    Exit non-zero if generated output differs from committed file.
```

## `ops/lint-shell.sh`

```text
Usage: ops/lint-shell.sh [--help] [--no-color] [path ...]

Run shellcheck and shellharden linting across shell scripts.
When paths are provided, only lint those files.
```

## `ops/profile/list.sh`

```text
Usage: ops/profile/list.sh [--help] [--no-color]

List available machine profiles.
```

## `ops/profile/set.sh`

```text
Usage: ops/profile/set.sh [--help] [--no-color] <profile-name>

Set the active machine profile in local/profile.env.
```

## `ops/profile/show.sh`

```text
Usage: ops/profile/show.sh [--help] [--no-color]

Show the active machine profile and its stow package selection.
```

## `ops/restore-backup.sh`

```text
Usage: ops/restore-backup.sh [--help] [--no-color] [--dry-run]

Restore machine-specific files from the latest backup.
```

## `ops/sync-brew.sh`

```text
Usage: ops/sync-brew.sh [--help] [--no-color] [--dry-run]

Sync manually installed Homebrew packages into tracked Brewfiles.
```

## `ops/update-repos.sh`

```text
Usage: ops/update-repos.sh [--help] [--no-color] [--dry-run] [--quiet] [--compact] [--jobs N] [--timeout N] [path]

Update all git repositories under the provided path (default: $DOTFILES_DEVELOPER_ROOT).

Options:
  --jobs N, -j N     Parallel jobs (default: 15)
  --timeout N, -t N  Fetch timeout in seconds (default: 30)
  --dry-run          Preview without making changes
  --quiet            Output one-line summary only
  --compact          Stream only updated/failed repositories plus summary
  --no-color         Disable colored output
```

## `ops/update.sh`

```text
Usage: ops/update.sh [--help] [--no-color]

Update repos, Homebrew packages, runtime tools, global packages, and restow configs.
```

## `setup/bootstrap-verify.sh`

```text
Usage: setup/bootstrap-verify.sh [--help] [--no-color] [--skip-doctor]

Runs bootstrap verification:
  1. install.sh dry-run
  2. script CLI tests
  3. docs sync check
  4. quick doctor check
```

## `setup/check-keychain.sh`

```text
Usage: setup/check-keychain.sh [--help] [--no-color] [--config <path>]

Validate required keychain items listed one service name per line.
Default config: local/keychain-required.txt
```

## `setup/generate-gpg-keys.sh`

```text
Usage: setup/generate-gpg-keys.sh [--help] [--no-color]

Generate a GPG key for commit signing and configure Git to use it.
```

## `setup/generate-ssh-keys.sh`

```text
Usage: setup/generate-ssh-keys.sh [--help] [--no-color]

Generate SSH keys for personal and (optionally) work identities.
```

## `setup/install-hooks.sh`

```text
Usage: setup/install-hooks.sh [--help] [--no-color]

Install git hooks from hooks/ into .git/hooks via symlinks.
```

## `setup/macos-defaults.sh`

```text
Usage: setup/macos-defaults.sh [--help] [--no-color]

Apply macOS system defaults (Finder, Dock, keyboard, trackpad, etc.).
Run once after fresh install, then selectively as needed.
```

## `setup/new-tool.sh`

```text
Usage: setup/new-tool.sh <name> [--brew <formula>] [--cask <cask>] [--config-dir] [--help] [--no-color]

Scaffold a new config package.

Options:
  --brew <formula>  Add a brew formula to Brewfile.cli
  --cask <cask>     Add a cask to Brewfile.apps
  --config-dir      Create .config/<name>/ structure
  --no-color        Disable colored output
  --help, -h        Show this help message
```

## `setup/remove-bloatware.sh`

```text
Usage: setup/remove-bloatware.sh [--help] [--no-color] [--dry-run] [--yes]

Remove common macOS bloatware apps (Tips, Chess, Stocks, etc.).
```

## `setup/stow-all.sh`

```text
Usage: setup/stow-all.sh [--help] [--no-color] [--quiet]

Stow all packages from config/ into $HOME.

Options:
  --quiet            Output one-line summary only
  --no-color         Disable colored output
```

## `setup/stow-report.sh`

```text
Usage: setup/stow-report.sh [--help] [--no-color]

Preview stow operations and report package conflicts.
```

## `setup/unstow-all.sh`

```text
Usage: setup/unstow-all.sh [--help] [--no-color]

Unstow all packages from config/ out of $HOME.
```

## `setup/vscode-setup.sh`

```text
Usage: setup/vscode-setup.sh [--help]

Install VS Code extensions declared in config/vscode/.../extensions.txt.
Skips extensions that are already installed.
```

