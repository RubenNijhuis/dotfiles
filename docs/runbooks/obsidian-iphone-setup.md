# Runbook: cross-platform Obsidian without Obsidian Sync

## Decision

Use one local Markdown vault on every device. The current iCloud-backed vault
is source material only; it is not the long-term sync mechanism because iCloud
Drive is unsuitable for the Windows part of this setup.

```text
macOS / Linux / Windows:
  ~/Files/30 Resources/Knowledge/Ruben Knowledge/

iPhone / iPad:
  On My iPhone/Obsidian/Ruben Knowledge/

Sync transport:
  one private Nextcloud/WebDAV directory
```

The local folder is authoritative on each device; WebDAV replicates it. This
keeps every desktop vault inside `~/Files`, makes the iPhone vault available
offline, and prevents iCloud, Syncthing, Git, or another sync service from
also managing the same files.

## Target vault structure

The vault mirrors the durable-file structure while keeping notes in one
phone-accessible Markdown vault:

```text
~/Files/30 Resources/Knowledge/Ruben Knowledge/
├── 00 Inbox/                 # capture first; sort during review
├── 10 Projects/              # active personal projects
├── 20 Areas/                 # continuing responsibilities
│   ├── Career & Employment/
│   ├── Finance & Business/
│   └── Legal & Records/
├── 30 Resources/             # reusable notes and research
│   └── Systems & Setup/
├── 40 Archive/               # inactive notes and former-work material
│   └── Former Work/
└── .obsidian/                # application settings; retain as-is
```

Loose uncategorised notes go to `00 Inbox`; no content is deleted as part of
this migration. Former-work notes move to `40 Archive/Former Work/`, while
active non-code work goes to `10 Projects/` or the appropriate `20 Areas/`
folder. The migration preserves original filenames until a later, deliberate
review can improve titles or combine genuinely duplicate notes.

## Migration from the current iCloud vault

1. In Finder, open **iCloud Drive → Obsidian** and download every item.
2. Create and verify a dated local backup in
   `~/Private/System Migration/Obsidian Vault Backups/`.
3. Create `~/Files/30 Resources/Knowledge/Ruben Knowledge/`.
4. Move every current vault item, including the hidden `.obsidian` folder,
   into that named folder. Do not merge it with another vault.
5. Open that named folder as the vault in Obsidian on the Mac and verify it
   works offline.
6. Keep the dated backup until the cross-device setup has been stable for at least
   30 days.

Do not delete the original vault, its `.obsidian` folder, or its iCloud copy.
The `.obsidian` folder holds themes, layouts, and plugin settings.

## Cross-platform sync setup

1. Provision one private Nextcloud/WebDAV directory and a dedicated account or
   app password. Do not store credentials in Nix, Git, or the vault.
2. Install the same maintained WebDAV sync community plugin in Obsidian on
   every device. Configure its credential through each device's secure store.
3. On the iPhone, create a local vault at
   **On My iPhone → Obsidian → Ruben Knowledge**; do not use iCloud.
4. Connect each local vault to the one WebDAV directory, one device at a time.
   Sync the Mac first, then initialise every other device from that remote copy.
5. Create a harmless test note on one device and confirm it arrives on another.
   Test a deliberate simultaneous edit and retain the conflict copy.

## Boundaries and future migration

- Do not use iCloud Drive, Syncthing, Git, or another file synchronizer on the
  same live vault after WebDAV is configured.
- The WebDAV plugin route is community-maintained rather than officially
  supported by Obsidian. It is the independence tradeoff for a free,
  cross-platform iPhone setup; validate it first with harmless test notes.
- Do not use Syncthing for the iPhone vault; iOS does not offer a reliable
  official background client.
- Sync is not backup. Keep a separate encrypted backup of the vault outside
  the synced folder.
