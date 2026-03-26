# CLI Reference

Generated from live `--help` output. Do not edit manually; run `bash scripts/maintenance/generate-cli-reference.sh`.

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
  --with-bloatware-removal      Remove common macOS bloatware apps
  --without-bloatware-removal   Skip bloatware removal
  --no-color                    Disable colored output
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
  uninstall-all     Unload and remove all installed LaunchD agents
  list              List all available agents
  status            Show status of installed agents
  restart <agent>   Restart a running agent

Available agents:
  dotfiles-backup      Automated daily backups
  dotfiles-doctor      Daily health monitoring
  obsidian-sync        Obsidian vault synchronization
  repo-update          Repository updates
  log-cleanup          Weekly log rotation
  brew-audit           Weekly Brewfile drift detection
  weekly-digest        Weekly automation health digest

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
Usage: scripts/automation/setup-automation.sh [--help] [--no-color] <target>

Targets:
  backup         Setup backup automation only
  doctor         Setup health monitoring only
  repo-update    Setup repository update automation only
  obsidian-sync  Setup Obsidian vault sync only
  lmstudio       Setup LM Studio server only
  log-cleanup    Setup log rotation only
  brew-audit     Setup Brewfile drift detection only
  weekly-digest  Setup weekly automation digest only
  setup-all      Setup all applicable automations (auto-detects optional agents)

Examples:
  scripts/automation/setup-automation.sh backup
  scripts/automation/setup-automation.sh setup-all
```

## `scripts/automation/show-agent-status.sh`

```text
Usage: scripts/automation/show-agent-status.sh <title> <agent-id> <recent-label> <recent-source> <log-glob> [lines]

Display launchd agent status, recent activity, and log files.

Arguments:
  title          Display title (e.g., "Backup Automation")
  agent-id       launchd agent label (e.g., "com.user.dotfiles-backup")
  recent-label   Label for the recent activity section
  recent-source  Directory (uses ls) or log file (uses tail) — ~ is expanded
  log-glob       Glob pattern for log files under ~/.local/log/
  lines          Lines to tail from log file (default: 10)
```

## `scripts/automation/sync-obsidian.sh`

```text
Usage: scripts/automation/sync-obsidian.sh [--help] [--no-color] [path]

Sync an Obsidian git repository (default: $DOTFILES_DEVELOPER_ROOT/personal/projects/obsidian-store).
```

## `scripts/automation/weekly-digest.sh`

```text
Usage: scripts/automation/weekly-digest.sh [--help] [--no-color]

Summarize automation health over the past 7 days and send a notification.
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

## `scripts/bootstrap/macos-defaults.sh`

```text
Usage: scripts/bootstrap/macos-defaults.sh [--help] [--no-color]

Apply macOS system defaults (Finder, Dock, keyboard, trackpad, etc.).
Run once after fresh install, then selectively as needed.
```

## `scripts/bootstrap/new-tool.sh`

```text
Usage: scripts/bootstrap/new-tool.sh <name> [--brew <formula>] [--cask <cask>] [--config-dir] [--help] [--no-color]

Scaffold a new stow package.

Arguments:
  name              Package name (e.g., ripgrep, lazydocker)

Options:
  --brew <formula>  Add a brew formula to Brewfile.cli
  --cask <cask>     Add a cask to Brewfile.apps
  --config-dir      Create .config/<name>/ structure (default: config in home root)
  --no-color        Disable colored output
  --help, -h        Show this help message

Examples:
  scripts/bootstrap/new-tool.sh ripgrep --brew ripgrep
  scripts/bootstrap/new-tool.sh lazydocker --brew lazydocker --config-dir
  scripts/bootstrap/new-tool.sh wezterm --cask wezterm --config-dir
```

## `scripts/bootstrap/remove-bloatware.sh`

```text
Usage: scripts/bootstrap/remove-bloatware.sh [options]

Remove common macOS bloatware apps (GUI applications only).
Apps in /System/Applications require sudo; you will be prompted once.

Options:
  --yes        Skip confirmation prompts
  --dry-run    List apps to remove without actually removing them
  --no-color   Disable colour output
  --help, -h   Show this help
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

## `scripts/bootstrap/vscode-setup.sh`

```text
Usage: scripts/bootstrap/vscode-setup.sh [--help]

Install VS Code extensions declared in stow/vscode/.../extensions.txt.
Skips extensions that are already installed.
```

## `scripts/health/check-launchd-contracts.sh`

```text
Usage: scripts/health/check-launchd-contracts.sh [--help] [--no-color]

Validate templates/launchd/*.plist against repository launchd contract.
```

## `scripts/health/check-vscode-parity.sh`

```text
Usage: scripts/health/check-vscode-parity.sh [--help] [--no-color] [--check]

Verify VS Code extension parity between extensions.txt and Brewfile.vscode.

Options:
  --check     Exit non-zero if drift is detected (for CI/Makefile use)
  --no-color  Disable colored output
  --help      Show this help message
```

## `scripts/health/doctor-notify.sh`

```text
Usage: scripts/health/doctor-notify.sh [--help] [--no-color] [--full]

Run doctor checks and show a macOS notification when issues are found.
Defaults to quick mode; use --full for full checks.
```

## `scripts/health/doctor.sh`

```text
Usage: scripts/health/doctor.sh [--help] [--quick] [--status] [--section <name>] [--no-color]

Comprehensive system health check for dotfiles setup.

Options:
  --quick             Run a reduced set of checks (skip slow network/brew checks)
  --status            Show quick actionable system status summary
  --section <name>    Run only the specified check section
  --no-color          Disable colored output
  --help, -h          Show this help message

Sections:
  profile, stow, ssh, gpg, git, shell, developer, runtime,
  launchd, homebrew, vscode, backup, biome, tmux, neovim, starship, shell-perf
```

## `scripts/health/gpg-info.sh`

```text
Usage: scripts/health/gpg-info.sh [--help] [--no-color]

Display GPG key and signing configuration status.
```

## `scripts/health/profile-shell.sh`

```text
Usage: scripts/health/profile-shell.sh [--help] [--no-color] [--analyze] [--full]

Without flags, generates shell profile data.
With --analyze, reads /tmp/zsh-profile.log and prints analysis.
With --full, generates profile data then immediately prints analysis.
```

## `scripts/health/ssh-info.sh`

```text
Usage: scripts/health/ssh-info.sh [--help] [--no-color]

Display SSH key, agent, and config status.
```

## `scripts/maintenance/brew-audit.sh`

```text
Usage: scripts/maintenance/brew-audit.sh [--help] [--no-color] [--check]

Audit Brewfiles against currently installed formulae, casks, and VS Code extensions.

Options:
  --check   Exit non-zero when drift is found.
```

## `scripts/maintenance/clean-all.sh`

```text
Usage: scripts/maintenance/clean-all.sh [--help] [--no-color] [--dry-run]

Remove dotfiles backup directories and Homebrew download cache.
Run after clean.sh for a full cleanup.
```

## `scripts/maintenance/clean.sh`

```text
Usage: scripts/maintenance/clean.sh [--help] [--no-color] [--dry-run]

Remove zsh caches, automation log files, and .DS_Store files from the repo.

Options:
  --dry-run     Preview what would be removed without deleting anything
  --no-color    Disable colored output
  --help        Show this help message
```

## `scripts/maintenance/cleanup-logs.sh`

```text
Usage: scripts/maintenance/cleanup-logs.sh [--help] [--no-color] [--days N]

Delete automation log files older than N days (default: 30).
```

## `scripts/maintenance/format-all.sh`

```text
Usage: scripts/maintenance/format-all.sh [--help] [--no-color]

Run Biome formatting on JS/TS/JSON files and ensure shell scripts are executable.
EditorConfig handles whitespace, line endings, and indentation via your editor.
```

## `scripts/maintenance/generate-cli-reference.sh`

```text
Usage: scripts/maintenance/generate-cli-reference.sh [--help] [--no-color] [--check]

Generate docs/reference/cli.md from --help output.

Options:
  --check    Exit non-zero if generated output differs from committed file.
```

## `scripts/maintenance/lint-shell.sh`

```text
Usage: scripts/maintenance/lint-shell.sh [--help] [--no-color] [path ...]

Run bash syntax and shellcheck linting across shell scripts.
When paths are provided, only lint those files.
```

## `scripts/maintenance/sync-brew.sh`

```text
Usage: scripts/maintenance/sync-brew.sh [--help] [--no-color] [--dry-run]

Sync manually installed Homebrew packages into tracked Brewfiles.
```

## `scripts/maintenance/update-repos.sh`

```text
Usage: scripts/maintenance/update-repos.sh [--help] [--no-color] [--dry-run] [--jobs N] [--timeout N] [path]

Update all git repositories under the provided path (default: $DOTFILES_DEVELOPER_ROOT).

Options:
  --jobs N, -j N     Number of parallel jobs (default: 15, 1 = sequential)
  --timeout N, -t N  Fetch timeout in seconds per repo (default: 30)
  --dry-run          Show what would be updated without making changes
  --no-color         Disable colored output
  --help             Show this help message
```

## `scripts/maintenance/update.sh`

```text
Usage: scripts/maintenance/update.sh [--help] [--no-color]

Update Homebrew packages, runtime tools, and restow configs.
```

