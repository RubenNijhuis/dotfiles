#!/usr/bin/env bash
#
# Sync Obsidian vault to remote repository
# Runs daily to backup local changes

set -e

VAULT_PATH="$HOME/Developer/repositories/obsidian-store"
LOG_FILE="$HOME/.local/log/obsidian-sync.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check if vault directory exists
if [[ ! -d "$VAULT_PATH" ]]; then
    log "ERROR: Vault directory not found at $VAULT_PATH"
    exit 1
fi

cd "$VAULT_PATH" || exit 1

# Check if there are any changes
if git diff-index --quiet HEAD -- 2>/dev/null; then
    log "No changes to sync"
    exit 0
fi

log "Starting Obsidian vault sync..."

# Stage all changes
git add -A

# Check if there are staged changes
if git diff-index --quiet --cached HEAD -- 2>/dev/null; then
    log "No staged changes after git add"
    exit 0
fi

# Commit with timestamp
COMMIT_MSG="Automated vault backup: $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"

# Push to remote
if git push; then
    log "Successfully synced Obsidian vault"
else
    log "ERROR: Failed to push changes"
    exit 1
fi
