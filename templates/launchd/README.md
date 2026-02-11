# LaunchD Templates

LaunchD agent configurations for automated tasks on macOS.

## Obsidian Sync (`com.user.obsidian-sync.plist`)

Automated daily backup of Obsidian vault to git repository.

### Quick Start

```bash
~/dotfiles/scripts/install-obsidian-sync.sh
```

This will:
1. Copy the plist to `~/Library/LaunchAgents/`
2. Load the agent with launchd
3. Schedule daily syncs at 20:00 (8 PM)

### Configuration

**Vault Path**: `~/Developer/repositories/obsidian-store`
**Schedule**: Daily at 20:00 (8 PM)
**Logs**: `~/.local/log/obsidian-sync.log`

To change the sync time, edit the plist before installation:
- Modify `<key>Hour</key>` and `<key>Minute</key>` values
- Re-run the install script

### Manual Operations

**Run sync now:**
```bash
~/dotfiles/scripts/sync-obsidian.sh
```

**View logs:**
```bash
tail -f ~/.local/log/obsidian-sync.log
```

**Check agent status:**
```bash
launchctl list | grep obsidian-sync
```

**Reload agent (after changes):**
```bash
launchctl unload ~/Library/LaunchAgents/com.user.obsidian-sync.plist
launchctl load ~/Library/LaunchAgents/com.user.obsidian-sync.plist
```

**Uninstall:**
```bash
launchctl unload ~/Library/LaunchAgents/com.user.obsidian-sync.plist
rm ~/Library/LaunchAgents/com.user.obsidian-sync.plist
```

### How It Works

The sync script:
1. Checks for changes in the Obsidian vault
2. Stages all modified/new files (`git add -A`)
3. Commits with timestamp
4. Pushes to remote repository
5. Logs all activity

If there are no changes, the script exits without committing.
