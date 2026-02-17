# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## Local Models (LM Studio)

### Configuration
- **Provider**: LM Studio running on http://127.0.0.1:1234
- **Primary Model**: mistralai/devstral-small-2-2512
  - Context: 32K tokens
  - Best for: Coding, technical tasks, structured output
- **Secondary Model**: openai/gpt-oss-20b
  - Context: 8K tokens
  - Best for: General conversation, simpler tasks

### Server Management
- Start LM Studio server: Open LM Studio > Developer > Start Server
- Check status: `curl http://127.0.0.1:1234/v1/models`
- Models must be loaded in LM Studio UI before use

### Privacy Notes
- All processing happens locally
- No data sent to external APIs (running in local-only mode)
- WhatsApp messages processed through local models only

---

## Reminders & Scheduling

### Quick Reminder Script
Use the reminder helper for easy reminders:
```bash
~/.openclaw/workspace/reminder-helper.sh "TIME" "MESSAGE"
```

**Examples:**
```bash
# Remind at 4pm today
~/.openclaw/workspace/reminder-helper.sh "16:00" "Check DJ cables in Leiden"

# Remind in 30 minutes
~/.openclaw/workspace/reminder-helper.sh "+30m" "Take a break"

# Remind in 2 hours
~/.openclaw/workspace/reminder-helper.sh "+2h" "Meeting prep"

# Remind tomorrow at 9am
~/.openclaw/workspace/reminder-helper.sh "2026-02-13T09:00:00" "Morning standup"
```

### Direct Cron Commands
```bash
# View all reminders
openclaw cron list

# Add a one-time reminder
openclaw cron add --name "Reminder name" --at "2026-02-12T16:00:00" \
  --message "Your reminder message" --channel whatsapp \
  --to "+31628634244" --announce --delete-after-run

# Add reminder in X minutes/hours
openclaw cron add --name "Quick reminder" --at "30m" \
  --message "30 minute reminder" --channel whatsapp \
  --to "+31628634244" --announce --delete-after-run

# Run a reminder now (testing)
openclaw cron run JOB_ID

# Delete a reminder
openclaw cron rm JOB_ID

# View reminder history
openclaw cron runs
```

### Recurring Reminders
```bash
# Every day at 9am (cron format: minute hour day month dayofweek)
openclaw cron add --name "Daily standup" --cron "0 9 * * *" \
  --message "Time for standup!" --channel whatsapp \
  --to "+31628634244" --announce

# Every 30 minutes
openclaw cron add --name "Hydration check" --every "30m" \
  --message "Drink water!" --channel whatsapp \
  --to "+31628634244" --announce

# Every weekday at 5pm
openclaw cron add --name "End of day" --cron "0 17 * * 1-5" \
  --message "Time to wrap up!" --channel whatsapp \
  --to "+31628634244" --announce
```

---

Add whatever helps you do your job. This is your cheat sheet.
