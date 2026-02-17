# LaunchD Task Examples

Concise, reusable examples for creating new LaunchD automations.

## Start Here

Use the manager as the canonical interface:

```bash
~/dotfiles/scripts/launchd-manager.sh list
~/dotfiles/scripts/launchd-manager.sh install <name>
~/dotfiles/scripts/launchd-manager.sh status
```

For managed built-in agents, prefer:

```bash
~/dotfiles/scripts/launchd-manager.sh install-all
```

Operational status:

```bash
make ops-status
```

## Minimal Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="$HOME/.local/log/<task>.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log "start"
# task logic
log "done"
```

## Minimal Plist Template

Use placeholders; they are rendered during install.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.<task></string>
  <key>ProgramArguments</key>
  <array>
    <string>__DOTFILES__/scripts/<task>.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>__HOME__/.local/log/<task>.out.log</string>
  <key>StandardErrorPath</key>
  <string>__HOME__/.local/log/<task>.err.log</string>
</dict>
</plist>
```

## Scheduling Patterns

### Daily

```xml
<key>StartCalendarInterval</key>
<dict>
  <key>Hour</key><integer>2</integer>
  <key>Minute</key><integer>0</integer>
</dict>
```

### Weekly

```xml
<key>StartCalendarInterval</key>
<dict>
  <key>Weekday</key><integer>1</integer>
  <key>Hour</key><integer>9</integer>
  <key>Minute</key><integer>0</integer>
</dict>
```

### Fixed Interval

```xml
<key>StartInterval</key>
<integer>3600</integer>
```

## Installation Flow for New Task

1. Add script: `scripts/<task>.sh`
2. `chmod +x scripts/<task>.sh`
3. Add plist: `templates/launchd/com.user.<task>.plist`
4. Install:

```bash
~/dotfiles/scripts/launchd-manager.sh install <task>
```

5. Verify:

```bash
launchctl print gui/$(id -u)/com.user.<task>
```

## Practical Example Ideas

- Database backup + retention
- Downloads cleanup
- API health check with notifications
- Screenshot organizer
- Weekly package updates

## Troubleshooting

```bash
# Validate plist
plutil -lint ~/Library/LaunchAgents/com.user.<task>.plist

# Force run
launchctl kickstart -k gui/$(id -u)/com.user.<task>

# Inspect state
launchctl print gui/$(id -u)/com.user.<task>
```

If install fails due to permissions, rerun the command outside sandboxed tooling.

## Related

- `templates/launchd/README.md`
- `scripts/launchd-manager.sh`
- `docs/reference/cli.md`
