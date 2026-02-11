# LaunchD Automation

LaunchD is macOS's native task scheduling system, superior to cron for macOS automation. This directory contains templates and tools for managing scheduled tasks.

## 📚 Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Adding New Tasks](#adding-new-tasks)
- [Existing Tasks](#existing-tasks)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Quick Start

### Install All Agents

```bash
~/dotfiles/scripts/install-launchd-agents.sh
```

### Install Individual Agent

```bash
~/dotfiles/scripts/install-launchd-agent.sh <agent-name>
# Example: ~/dotfiles/scripts/install-launchd-agent.sh obsidian-sync
```

---

## Architecture

### Directory Structure

```
dotfiles/
├── templates/launchd/          # LaunchD plist templates
│   ├── com.user.*.plist        # Agent configurations
│   └── README.md               # This file
├── scripts/
│   ├── install-launchd-agents.sh      # Install all agents
│   ├── install-launchd-agent.sh       # Install single agent
│   ├── uninstall-launchd-agent.sh     # Uninstall agent
│   ├── list-launchd-agents.sh         # List installed agents
│   └── <task-name>.sh                 # Task scripts
└── docs/
    └── launchd-guide.md        # Detailed LaunchD documentation
```

### Naming Convention

- **Plist files**: `com.user.<task-name>.plist`
- **Script files**: `<task-name>.sh`
- **Label**: Must match plist filename without `.plist`

### Installation Flow

1. Plist template lives in `templates/launchd/`
2. Installation script copies to `~/Library/LaunchAgents/`
3. LaunchD loads and schedules the agent
4. Agent runs the corresponding script in `scripts/`

---

## Adding New Tasks

### Step 1: Create the Task Script

Create your script in `~/dotfiles/scripts/<task-name>.sh`:

```bash
#!/usr/bin/env bash
#
# Brief description of what this script does

set -e

LOG_FILE="$HOME/.local/log/<task-name>.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting <task-name>..."

# Your task logic here

log "Completed <task-name>"
```

Make it executable:
```bash
chmod +x ~/dotfiles/scripts/<task-name>.sh
```

### Step 2: Create the LaunchD Plist

Create `~/dotfiles/templates/launchd/com.user.<task-name>.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.<task-name></string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>$HOME/dotfiles/scripts/<task-name>.sh</string>
    </array>

    <!-- Choose ONE scheduling method below -->

    <!-- OPTION 1: Run at specific time daily -->
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>20</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <!-- OPTION 2: Run at interval (every N seconds) -->
    <!--
    <key>StartInterval</key>
    <integer>3600</integer>
    -->

    <!-- OPTION 3: Run on specific days/times -->
    <!--
    <key>StartCalendarInterval</key>
    <array>
        <dict>
            <key>Weekday</key>
            <integer>1</integer>
            <key>Hour</key>
            <integer>9</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
    </array>
    -->

    <key>StandardOutPath</key>
    <string>/tmp/<task-name>.out</string>

    <key>StandardErrorPath</key>
    <string>/tmp/<task-name>.err</string>

    <key>RunAtLoad</key>
    <false/>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
```

### Step 3: Document Your Task

Add a section to this README under [Existing Tasks](#existing-tasks).

### Step 4: Install and Test

```bash
# Install the agent
~/dotfiles/scripts/install-launchd-agent.sh <task-name>

# Test manually
~/dotfiles/scripts/<task-name>.sh

# Verify it's loaded
launchctl list | grep <task-name>

# View logs
tail -f ~/.local/log/<task-name>.log
```

### Step 5: Commit to Repository

```bash
cd ~/dotfiles
git add templates/launchd/com.user.<task-name>.plist
git add scripts/<task-name>.sh
git add templates/launchd/README.md  # If you updated docs
git commit -m "Add <task-name> scheduled task"
git push
```

---

## Existing Tasks

### Obsidian Sync (`obsidian-sync`)

**Purpose**: Automated daily backup of Obsidian vault to git repository

**Schedule**: Daily at 20:00 (8 PM)

**Script**: `scripts/sync-obsidian.sh`

**Plist**: `templates/launchd/com.user.obsidian-sync.plist`

**Configuration**:
- Vault path: `~/Developer/repositories/obsidian-store`
- Logs: `~/.local/log/obsidian-sync.log`

**Manual Operations**:
```bash
# Run sync now
~/dotfiles/scripts/sync-obsidian.sh

# View logs
tail -f ~/.local/log/obsidian-sync.log

# Check status
launchctl list | grep obsidian-sync
```

---

## Common Patterns

### Scheduling Options

#### Daily at Specific Time
```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>14</integer>      <!-- 2 PM -->
    <key>Minute</key>
    <integer>30</integer>
</dict>
```

#### Every N Hours/Minutes
```xml
<key>StartInterval</key>
<integer>3600</integer>  <!-- Every hour (in seconds) -->
```

#### Specific Days and Times
```xml
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Weekday</key>
        <integer>1</integer>    <!-- Monday = 1, Sunday = 7 -->
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Weekday</key>
        <integer>5</integer>    <!-- Friday -->
        <key>Hour</key>
        <integer>17</integer>   <!-- 5 PM -->
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</array>
```

#### Multiple Times Per Day
```xml
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Hour</key>
        <integer>17</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</array>
```

### Script Patterns

#### Basic Template with Logging
```bash
#!/usr/bin/env bash
set -e

LOG_FILE="$HOME/.local/log/task.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Task started"
# Your code here
log "Task completed"
```

#### With Error Handling
```bash
#!/usr/bin/env bash
set -e

LOG_FILE="$HOME/.local/log/task.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Cleanup on exit"
}

error_handler() {
    log "ERROR: Script failed at line $1"
    exit 1
}

trap cleanup EXIT
trap 'error_handler $LINENO' ERR

log "Task started"
# Your code here
log "Task completed"
```

#### Git Repository Sync Pattern
```bash
#!/usr/bin/env bash
set -e

REPO_PATH="$HOME/path/to/repo"
LOG_FILE="$HOME/.local/log/repo-sync.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

cd "$REPO_PATH" || exit 1

# Check for changes
if git diff-index --quiet HEAD -- 2>/dev/null; then
    log "No changes to sync"
    exit 0
fi

log "Syncing repository..."
git add -A
git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
git push

log "Sync completed"
```

#### File Cleanup Pattern
```bash
#!/usr/bin/env bash
set -e

TARGET_DIR="$HOME/Downloads"
DAYS_OLD=30
LOG_FILE="$HOME/.local/log/cleanup.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting cleanup of files older than $DAYS_OLD days..."

# Find and delete old files
COUNT=$(find "$TARGET_DIR" -type f -mtime +$DAYS_OLD | wc -l | tr -d ' ')

if [ "$COUNT" -gt 0 ]; then
    find "$TARGET_DIR" -type f -mtime +$DAYS_OLD -delete
    log "Deleted $COUNT files"
else
    log "No files to delete"
fi

log "Cleanup completed"
```

#### Health Check Pattern
```bash
#!/usr/bin/env bash
set -e

SERVICE_URL="https://example.com/health"
LOG_FILE="$HOME/.local/log/health-check.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Checking service health..."

if curl -sf "$SERVICE_URL" > /dev/null; then
    log "Service is healthy"
else
    log "ERROR: Service health check failed"
    # Optional: Send notification
    exit 1
fi
```

---

## Troubleshooting

### Agent Not Running

**Check if loaded**:
```bash
launchctl list | grep com.user
```

**View error logs**:
```bash
tail -f /tmp/<task-name>.err
cat /tmp/<task-name>.out
```

**Reload agent**:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.<task-name>.plist
launchctl load ~/Library/LaunchAgents/com.user.<task-name>.plist
```

### Agent Runs But Script Fails

**Check script logs**:
```bash
tail -f ~/.local/log/<task-name>.log
```

**Test script manually**:
```bash
~/dotfiles/scripts/<task-name>.sh
```

**Common issues**:
- Script not executable: `chmod +x ~/dotfiles/scripts/<task-name>.sh`
- PATH issues: Add full paths to commands or set PATH in plist
- Permissions: Check file/directory permissions

### Debugging Tips

**Enable verbose logging in script**:
```bash
#!/usr/bin/env bash
set -ex  # Add 'x' for verbose output
```

**Check system logs**:
```bash
log show --predicate 'subsystem == "com.apple.launchd"' --last 1h
```

**Validate plist syntax**:
```bash
plutil -lint ~/Library/LaunchAgents/com.user.<task-name>.plist
```

### Common Errors

**`PATH not found`**
- Add full path to binaries in script
- Or set PATH in plist EnvironmentVariables

**`Permission denied`**
- Script not executable: `chmod +x script.sh`
- File ownership issues: Check with `ls -la`

**`Agent loads but never runs`**
- Check schedule in plist
- Verify `RunAtLoad` is set correctly
- Use `launchctl kickstart -k gui/$(id -u)/com.user.<task-name>` to force run

---

## References

### Official Documentation
- [launchd.info](https://www.launchd.info/) - Comprehensive guide
- [Apple Developer Docs](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

### Quick Reference

**List all user agents**:
```bash
launchctl list | grep com.user
```

**Load agent**:
```bash
launchctl load ~/Library/LaunchAgents/com.user.<name>.plist
```

**Unload agent**:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.<name>.plist
```

**Force run agent**:
```bash
launchctl kickstart -k gui/$(id -u)/com.user.<name>
```

**View agent info**:
```bash
launchctl print gui/$(id -u)/com.user.<name>
```

**View scheduled times**:
```bash
launchctl print gui/$(id -u)/com.user.<name> | grep "next execution"
```

---

## Examples

See `docs/launchd-examples.md` for complete working examples of:
- Database backups
- System maintenance
- Git repository syncing
- File cleanup
- Health checks
- API polling
- Report generation
- And more...
