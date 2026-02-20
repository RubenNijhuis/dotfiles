# LaunchD Automation

Canonical launchd automation contract for this repository.

## Quick Start

```bash
# Show available agents
~/dotfiles/scripts/automation/launchd-manager.sh list

# Install all managed agents
~/dotfiles/scripts/automation/launchd-manager.sh install-all

# Install one agent
~/dotfiles/scripts/automation/launchd-manager.sh install obsidian-sync

# Show loaded status
~/dotfiles/scripts/automation/launchd-manager.sh status

# Restart or remove one agent
~/dotfiles/scripts/automation/launchd-manager.sh restart obsidian-sync
~/dotfiles/scripts/automation/launchd-manager.sh uninstall obsidian-sync
```

## Managed Agents

- `dotfiles-backup`: daily dotfiles backup at 02:00.
- `dotfiles-doctor`: daily health check + notifications at 09:00.
- `obsidian-sync`: daily vault sync.
- `repo-update`: scheduled repository updates with notification wrapper.

Templates live in `templates/launchd/com.user.*.plist`.
Installation renders local paths from placeholders (`__DOTFILES__`, `__HOME__`).

## Add a New Task

1. Create script: `scripts/<task-name>.sh`.
2. Make it executable: `chmod +x scripts/<task-name>.sh`.
3. Create plist template: `templates/launchd/com.user.<task-name>.plist`.
4. Follow the contract below.
4. Install with manager:
```bash
~/dotfiles/scripts/automation/launchd-manager.sh install <task-name>
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

If a job uses non-standard log names, document them in this file and surface them in `scripts/automation/ops-status.sh`.

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
    <string>__DOTFILES__/scripts/<task-name>.sh</string>
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
make backup-setup
make doctor-setup
make repo-update-setup
make ops-status
```

## More Examples

- `docs/launchd-examples.md` for end-to-end examples.
- `scripts/automation/launchd-manager.sh` for the canonical command surface.
