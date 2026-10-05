# LaunchD Automation

Canonical launchd automation contract for this repository.

## Quick Start

```bash
# Show available agents
make automation-list

# Install only the active profile's selected agents
make launchd-install-all

# Install one agent

# Show loaded status
make launchd-status

# Restart or remove one agent
```

## Managed Agents

The personal laptop selects only `update-audit`; the minimal profile selects
none. Everything else below is available for deliberate opt-in. An empty
automation list never enables all jobs. Changing selection does not uninstall
or unload any existing agent; inspect and approve those exact targets separately.

- `dotfiles-backup`: daily dotfiles backup at 02:00.
- `dotfiles-doctor`: daily health check + notifications at 09:00.
- `update-audit`: weekly update availability report at Monday 09:15.
- `repo-update`: scheduled repository updates with notification wrapper.
- `log-cleanup`: weekly log rotation.
- `brew-audit`: weekly Brewfile drift detection.
- `weekly-digest`: weekly automation health digest.
- `lmstudio-server`: LM Studio local server.

Templates live in `launchd/com.user.*.plist`.
Installation renders local paths from placeholders (`__DOTFILES__`, `__HOME__`).

## Add a New Task

1. Create script: `ops/<task-name>.sh`.
2. Make it executable: `chmod +x ops/<task-name>.sh`.
3. Create plist template: `launchd/com.user.<task-name>.plist`.
4. Follow the contract below.
4. Install with manager:
```bash
bash ops/automation/launchd-manager.sh install <task-name>
```
5. Verify:
```bash
launchctl print gui/$(id -u)/com.user.<task-name>
```

## Launchd Contract

Every `com.user.<task>.plist` template must include:

- `<key>Label</key>` with value `com.user.<task>`
- `<key>ProgramArguments</key>` using `__DOTFILES__` placeholder path
- `<key>StandardOutPath</key>` and `<key>StandardErrorPath</key>` under `__HOME__/.local/log/`
- deterministic schedule (`RunAtLoad`, `StartCalendarInterval`, or `StartInterval`)

If a job uses non-standard log names, document them in this file and surface them in `health/doctor.sh --automation`.

## Minimal Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="$HOME/.local/log/<task-name>.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] started" >> "$LOG_FILE"
# task logic
echo "[$(date '+%Y-%m-%d %H:%M:%S')] finished" >> "$LOG_FILE"
```

## Minimal Plist Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.<task-name></string>
  <key>ProgramArguments</key>
  <array>
    <string>__DOTFILES__/ops/<task-name>.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>__HOME__/.local/log/<task-name>.out.log</string>
  <key>StandardErrorPath</key>
  <string>__HOME__/.local/log/<task-name>.err.log</string>
</dict>
</plist>
```

## Troubleshooting

```bash
# Lint plist
plutil -lint ~/Library/LaunchAgents/com.user.<task-name>.plist

# Force run now
launchctl kickstart -k gui/$(id -u)/com.user.<task-name>

# Inspect launchd state
launchctl print gui/$(id -u)/com.user.<task-name>
```

If install fails with permissions, run the command outside sandboxed tooling.

## Operations Commands

```bash
make automation-setup
make doctor --automation
```

## Update Policy

`update-audit` runs every Monday at 09:15. It checks Nix inputs, documented
Homebrew packages, and macOS updates, then notifies when the available updates
or check failures change. The latest report is saved to
`~/.local/state/dotfiles/update-audit.txt`; unchanged results stay quiet.
It also detects when the Mac is still running a previous Nix generation after
the repository has been updated.
It intentionally does not install updates: Nix updates change the
tracked lockfile and macOS updates can require a restart, so both remain an
explicit review-and-apply step.

`ops/automation/launchd-manager.sh` is the canonical command surface.
