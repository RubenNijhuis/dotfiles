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
Usage: health/doctor.sh [--help] [--quick] [--status] [--section <name>] [--no-color]

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

## `health/gpg-info.sh`

```text
Usage: health/gpg-info.sh [--help] [--no-color]

Display GPG key and signing configuration status.
```

## `health/profile-shell.sh`

```text
Usage: health/profile-shell.sh [--help] [--no-color] [--analyze] [--full]

Without flags, generates shell profile data.
With --analyze, reads /tmp/zsh-profile.log and prints analysis.
With --full, generates profile data then immediately prints analysis.
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
  ops/automation/launchd-manager.sh install dotfiles-backup
  ops/automation/launchd-manager.sh install-all
  ops/automation/launchd-manager.sh status
  ops/automation/launchd-manager.sh restart dotfiles-doctor
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
  ops/automation/setup-automation.sh backup
  ops/automation/setup-automation.sh setup-all
```

## `ops/automation/show-agent-status.sh`

```text
Usage: ops/automation/show-agent-status.sh <title> <agent-id> <recent-label> <recent-source> <log-glob> [lines]

Display launchd agent status, recent activity, and log files.

Arguments:
  title          Display title (e.g., "Backup Automation")
  agent-id       launchd agent label (e.g., "com.user.dotfiles-backup")
  recent-label   Label for the recent activity section
  recent-source  Directory (uses ls) or log file (uses tail) — ~ is expanded
  log-glob       Glob pattern for log files under ~/.local/log/
  lines          Lines to tail from log file (default: 10)
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

Create a timestamped backup of local dotfile files before stow operations.
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

Remove dotfiles backup directories and Homebrew download cache.
Run after clean.sh for a full cleanup.
```

## `ops/clean.sh`

```text
Usage: ops/clean.sh [--help] [--no-color] [--dry-run]

Remove zsh caches, automation log files, and .DS_Store files from the repo.

Options:
  --dry-run     Preview what would be removed without deleting anything
  --no-color    Disable colored output
  --help        Show this help message
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

Run bash syntax and shellcheck linting across shell scripts.
When paths are provided, only lint those files.
```

## `ops/restore-backup.sh`

```text
Usage: ops/restore-backup.sh [--help] [--no-color] [--dry-run]

Restore files from the latest backup recorded in ~/.dotfiles-backup/latest.
```

## `ops/sync-brew.sh`

```text
Usage: ops/sync-brew.sh [--help] [--no-color] [--dry-run]

Sync manually installed Homebrew packages into tracked Brewfiles.
```

## `ops/update-repos.sh`

```text
Usage: ops/update-repos.sh [--help] [--no-color] [--dry-run] [--jobs N] [--timeout N] [path]

Update all git repositories under the provided path (default: $DOTFILES_DEVELOPER_ROOT).

Options:
  --jobs N, -j N     Number of parallel jobs (default: 15, 1 = sequential)
  --timeout N, -t N  Fetch timeout in seconds per repo (default: 30)
  --dry-run          Show what would be updated without making changes
  --no-color         Disable colored output
  --help             Show this help message
```

## `ops/update.sh`

```text
Usage: ops/update.sh [--help] [--no-color]

Update Homebrew packages, runtime tools, and restow configs.
```

## `setup/bootstrap-verify.sh`

```text
Usage: setup/bootstrap-verify.sh [--help] [--no-color] [--profile <personal|work>] [--skip-doctor]

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

Arguments:
  name              Package name (e.g., ripgrep, lazydocker)

Options:
  --brew <formula>  Add a brew formula to Brewfile.cli
  --cask <cask>     Add a cask to Brewfile.apps
  --config-dir      Create .config/<name>/ structure (default: config in home root)
  --no-color        Disable colored output
  --help, -h        Show this help message

Examples:
  setup/new-tool.sh ripgrep --brew ripgrep
  setup/new-tool.sh lazydocker --brew lazydocker --config-dir
  setup/new-tool.sh wezterm --cask wezterm --config-dir
```

## `setup/remove-bloatware.sh`

```text
Usage: setup/remove-bloatware.sh [options]

Remove common macOS bloatware apps (GUI applications only).
Apps in /System/Applications require sudo; you will be prompted once.

Options:
  --yes        Skip confirmation prompts
  --dry-run    List apps to remove without actually removing them
  --no-color   Disable colour output
  --help, -h   Show this help
```

## `setup/stow-all.sh`

```text
Usage: setup/stow-all.sh [--help] [--no-color]

Stow all packages from config/ into $HOME.
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

