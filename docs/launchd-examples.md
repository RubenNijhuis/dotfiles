# LaunchD Task Examples

Complete, working examples of common automation tasks using LaunchD.

## Table of Contents

1. [Database Backup](#database-backup)
2. [Git Repository Auto-Sync](#git-repository-auto-sync)
3. [Downloads Folder Cleanup](#downloads-folder-cleanup)
4. [System Health Monitor](#system-health-monitor)
5. [Time Machine Verification](#time-machine-verification)
6. [Homebrew Auto-Update](#homebrew-auto-update)
7. [Log Rotation](#log-rotation)
8. [API Health Check](#api-health-check)
9. [Screenshot Organizer](#screenshot-organizer)
10. [Battery Monitor](#battery-monitor)

---

## Database Backup

Automatically backup PostgreSQL database daily.

### Script: `postgres-backup.sh`

```bash
#!/usr/bin/env bash
set -e

DB_NAME="myapp_production"
BACKUP_DIR="$HOME/Backups/postgres"
BACKUP_FILE="${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).sql"
LOG_FILE="$HOME/.local/log/postgres-backup.log"
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting database backup..."

# Perform backup
if pg_dump "$DB_NAME" > "$BACKUP_FILE"; then
    log "Backup created: $BACKUP_FILE"

    # Compress backup
    gzip "$BACKUP_FILE"
    log "Backup compressed: ${BACKUP_FILE}.gz"

    # Delete old backups
    find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    log "Deleted backups older than $RETENTION_DAYS days"

    log "Backup completed successfully"
else
    log "ERROR: Backup failed"
    exit 1
fi
```

### Plist: `com.user.postgres-backup.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.postgres-backup</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>$HOME/dotfiles/scripts/postgres-backup.sh</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/postgres-backup.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/postgres-backup.err</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

---

## Git Repository Auto-Sync

Keep multiple git repositories synced automatically.

### Script: `git-multi-sync.sh`

```bash
#!/usr/bin/env bash
set -e

REPOS=(
    "$HOME/Developer/repositories/notes"
    "$HOME/Developer/repositories/documents"
    "$HOME/Developer/repositories/config"
)

LOG_FILE="$HOME/.local/log/git-multi-sync.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

sync_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")

    if [ ! -d "$repo_path" ]; then
        log "WARNING: Repository not found: $repo_path"
        return 1
    fi

    cd "$repo_path" || return 1

    # Check for changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        log "[$repo_name] No changes to sync"
        return 0
    fi

    log "[$repo_name] Syncing..."

    git add -A
    git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"

    if git push; then
        log "[$repo_name] ✓ Synced successfully"
    else
        log "[$repo_name] ✗ Failed to push"
        return 1
    fi
}

log "Starting multi-repository sync..."

for repo in "${REPOS[@]}"; do
    sync_repo "$repo"
done

log "Multi-repository sync completed"
```

---

## Downloads Folder Cleanup

Automatically clean up old files from Downloads folder.

### Script: `cleanup-downloads.sh`

```bash
#!/usr/bin/env bash
set -e

DOWNLOADS_DIR="$HOME/Downloads"
ARCHIVE_DIR="$HOME/Downloads/Archive"
DAYS_OLD=30
LOG_FILE="$HOME/.local/log/cleanup-downloads.log"

mkdir -p "$ARCHIVE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting Downloads cleanup..."

# Move old files to archive
moved_count=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        mv "$file" "$ARCHIVE_DIR/"
        ((moved_count++))
    fi
done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type f -mtime +$DAYS_OLD)

log "Moved $moved_count files to archive"

# Delete very old archived files (90 days)
deleted_count=$(find "$ARCHIVE_DIR" -type f -mtime +90 | wc -l | tr -d ' ')
find "$ARCHIVE_DIR" -type f -mtime +90 -delete

log "Deleted $deleted_count archived files older than 90 days"
log "Cleanup completed"
```

### Plist: Weekly execution

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Weekday</key>
    <integer>7</integer>  <!-- Sunday -->
    <key>Hour</key>
    <integer>12</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

---

## System Health Monitor

Monitor system resources and alert if thresholds exceeded.

### Script: `system-health-check.sh`

```bash
#!/usr/bin/env bash
set -e

LOG_FILE="$HOME/.local/log/system-health.log"
DISK_THRESHOLD=80  # Alert if disk usage > 80%
MEM_THRESHOLD=85   # Alert if memory usage > 85%

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    log "ALERT: $*"
    # Optional: Send notification
    osascript -e "display notification \"$*\" with title \"System Health Alert\""
}

# Check disk usage
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
    alert "Disk usage at ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
fi

# Check memory usage
mem_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print 100-$5}' | cut -d. -f1)
if [ "$mem_pressure" -gt "$MEM_THRESHOLD" ]; then
    alert "Memory pressure at ${mem_pressure}% (threshold: ${MEM_THRESHOLD}%)"
fi

log "Health check completed - Disk: ${disk_usage}%, Memory: ${mem_pressure}%"
```

### Plist: Every 30 minutes

```xml
<key>StartInterval</key>
<integer>1800</integer>  <!-- 30 minutes = 1800 seconds -->
```

---

## Time Machine Verification

Verify Time Machine backups are running successfully.

### Script: `verify-timemachine.sh`

```bash
#!/usr/bin/env bash
set -e

LOG_FILE="$HOME/.local/log/timemachine-verify.log"
ALERT_DAYS=7  # Alert if no backup in 7 days

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    log "ALERT: $*"
    osascript -e "display notification \"$*\" with title \"Time Machine Alert\""
}

# Get last backup date
last_backup=$(tmutil latestbackup 2>/dev/null)

if [ -z "$last_backup" ]; then
    alert "No Time Machine backups found"
    exit 1
fi

# Extract date from backup path (format: YYYY-MM-DD-HHMMSS)
backup_date=$(basename "$last_backup" | cut -d- -f1-3)
backup_timestamp=$(date -j -f "%Y-%m-%d" "$backup_date" +%s)
current_timestamp=$(date +%s)
days_ago=$(( (current_timestamp - backup_timestamp) / 86400 ))

if [ "$days_ago" -gt "$ALERT_DAYS" ]; then
    alert "Last backup was $days_ago days ago"
else
    log "Last backup: $days_ago days ago (OK)"
fi
```

---

## Homebrew Auto-Update

Keep Homebrew and packages up to date.

### Script: `brew-update.sh`

```bash
#!/usr/bin/env bash
set -e

LOG_FILE="$HOME/.local/log/brew-update.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting Homebrew update..."

# Update Homebrew
log "Updating Homebrew..."
brew update 2>&1 | tee -a "$LOG_FILE"

# Upgrade packages
log "Upgrading packages..."
outdated=$(brew outdated)

if [ -n "$outdated" ]; then
    log "Outdated packages:"
    echo "$outdated" | tee -a "$LOG_FILE"

    brew upgrade 2>&1 | tee -a "$LOG_FILE"
    log "Packages upgraded"
else
    log "All packages up to date"
fi

# Cleanup
log "Cleaning up..."
brew cleanup 2>&1 | tee -a "$LOG_FILE"

log "Homebrew update completed"
```

### Plist: Weekly on Monday morning

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Weekday</key>
    <integer>1</integer>  <!-- Monday -->
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

---

## Log Rotation

Rotate and compress application logs.

### Script: `rotate-logs.sh`

```bash
#!/usr/bin/env bash
set -e

LOG_DIR="$HOME/.local/log"
ROTATE_LOG="$LOG_DIR/log-rotation.log"
RETENTION_DAYS=30

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$ROTATE_LOG"
}

log "Starting log rotation..."

# Find all .log files
while IFS= read -r logfile; do
    if [ -f "$logfile" ] && [ "$logfile" != "$ROTATE_LOG" ]; then
        filename=$(basename "$logfile")

        # Rotate if file is larger than 10MB
        size=$(stat -f%z "$logfile")
        if [ "$size" -gt 10485760 ]; then
            timestamp=$(date +%Y%m%d_%H%M%S)
            rotated="${logfile}.${timestamp}"

            cp "$logfile" "$rotated"
            gzip "$rotated"
            > "$logfile"  # Truncate original

            log "Rotated and compressed: $filename"
        fi
    fi
done < <(find "$LOG_DIR" -name "*.log")

# Delete old compressed logs
deleted=$(find "$LOG_DIR" -name "*.log.*.gz" -mtime +$RETENTION_DAYS | wc -l | tr -d ' ')
find "$LOG_DIR" -name "*.log.*.gz" -mtime +$RETENTION_DAYS -delete

log "Deleted $deleted old compressed logs"
log "Log rotation completed"
```

---

## API Health Check

Monitor API endpoints for availability.

### Script: `api-health-check.sh`

```bash
#!/usr/bin/env bash
set -e

ENDPOINTS=(
    "https://api.example.com/health"
    "https://api.example.com/status"
)

LOG_FILE="$HOME/.local/log/api-health.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    log "ALERT: $*"
    osascript -e "display notification \"$*\" with title \"API Health Alert\""
}

check_endpoint() {
    local url="$1"
    local name=$(echo "$url" | sed 's|https\?://||' | sed 's|/.*||')

    if curl -sf --max-time 10 "$url" > /dev/null; then
        log "[$name] ✓ Healthy"
        return 0
    else
        alert "[$name] ✗ Unhealthy or unreachable"
        return 1
    fi
}

log "Starting API health checks..."

for endpoint in "${ENDPOINTS[@]}"; do
    check_endpoint "$endpoint"
done

log "Health checks completed"
```

### Plist: Every 5 minutes

```xml
<key>StartInterval</key>
<integer>300</integer>  <!-- 5 minutes = 300 seconds -->
```

---

## Screenshot Organizer

Organize screenshots into dated folders.

### Script: `organize-screenshots.sh`

```bash
#!/usr/bin/env bash
set -e

SCREENSHOTS_SOURCE="$HOME/Desktop"
SCREENSHOTS_DEST="$HOME/Pictures/Screenshots"
LOG_FILE="$HOME/.local/log/screenshot-organizer.log"

mkdir -p "$SCREENSHOTS_DEST"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Organizing screenshots..."

organized=0

# Find all screenshot files
while IFS= read -r screenshot; do
    if [ -f "$screenshot" ]; then
        # Get creation date
        date_dir=$(stat -f%SB -t%Y-%m "$screenshot")
        dest_dir="$SCREENSHOTS_DEST/$date_dir"

        mkdir -p "$dest_dir"
        mv "$screenshot" "$dest_dir/"

        ((organized++))
    fi
done < <(find "$SCREENSHOTS_SOURCE" -maxdepth 1 -name "Screenshot*.png")

log "Organized $organized screenshots"
```

### Plist: Daily at end of day

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>23</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

---

## Battery Monitor

Monitor battery health and log statistics.

### Script: `battery-monitor.sh`

```bash
#!/usr/bin/env bash
set -e

LOG_FILE="$HOME/.local/log/battery-stats.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Get battery info
battery_info=$(pmset -g batt)
percentage=$(echo "$battery_info" | grep -o '[0-9]\+%' | tr -d '%')
status=$(echo "$battery_info" | grep -o 'discharging\|charging\|charged' || echo "unknown")
health=$(system_profiler SPPowerDataType | grep "Condition" | awk '{print $2}')

# Log stats
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Battery: ${percentage}% | Status: ${status} | Health: ${health}" >> "$LOG_FILE"

# Alert if battery low and not charging
if [ "$percentage" -lt 20 ] && [ "$status" = "discharging" ]; then
    osascript -e "display notification \"Battery at ${percentage}%\" with title \"Low Battery Warning\""
fi

# Alert if battery health is poor
if [ "$health" != "Normal" ]; then
    osascript -e "display notification \"Battery health: ${health}\" with title \"Battery Health Alert\""
fi
```

### Plist: Every hour

```xml
<key>StartInterval</key>
<integer>3600</integer>  <!-- 1 hour = 3600 seconds -->
```

---

## Installation

To use any of these examples:

1. Copy the script to `~/dotfiles/scripts/<name>.sh`
2. Copy the plist to `~/dotfiles/templates/launchd/com.user.<name>.plist`
3. Make script executable: `chmod +x ~/dotfiles/scripts/<name>.sh`
4. Install: `~/dotfiles/scripts/install-launchd-agent.sh <name>`
5. Test: `~/dotfiles/scripts/<name>.sh`

---

## Tips

- Always test scripts manually before installing as agents
- Use absolute paths in scripts (launchd runs with minimal environment)
- Add comprehensive logging for troubleshooting
- Set appropriate error handling with `set -e`
- Consider notification for important alerts
- Keep logs under `~/.local/log/` for consistency
