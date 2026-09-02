# Runbook: Obsidian on Mac and iPhone without Obsidian Sync

## Decision

Use the existing iCloud-backed Obsidian vault as the single notes vault for
this Mac and iPhone. Obsidian stores notes as ordinary Markdown files, so this
does not use or require an Obsidian Sync subscription.

The vault must be a named folder inside the Obsidian iCloud Drive container:

```text
iCloud Drive/Obsidian/<vault>/
```

On macOS, that is managed by iCloud Drive rather than the `~/Files` hierarchy.
The contents still remain locally available when the folder is marked **Keep
Downloaded**. Do not create a second vault under `~/Files`; two active copies
would introduce ambiguous ownership and sync conflicts.

The current vault is a legacy root-level arrangement. Do not connect it to the
iPhone yet: first move its complete contents, including `.obsidian`, into one
named vault folder. This is a one-time file migration that happens only after
a complete verified backup is available.

## Target vault structure

The vault mirrors the durable-file structure while keeping notes in one
phone-accessible Markdown vault:

```text
Ruben Knowledge/
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

## Before connecting the iPhone

1. In Finder, open **iCloud Drive → Obsidian**.
2. Right-click the existing contents and choose **Keep Downloaded**.
3. Wait until cloud-download indicators have disappeared.
4. Create and verify a dated local backup in
   `~/Private/System Migration/Obsidian Vault Backups/`.
5. Create one destination folder, for example `Ruben Knowledge`, in
   **iCloud Drive → Obsidian**.
6. Move every current vault item, including the hidden `.obsidian` folder,
   into that named folder. Do not merge it with another vault.
7. Open that named folder as the vault in Obsidian on the Mac and verify it
   works offline.
8. Keep the dated backup until the iPhone setup has been stable for at least
   30 days.

Do not delete the original vault, its `.obsidian` folder, or its iCloud copy.
The `.obsidian` folder holds themes, layouts, and plugin settings.

## Connect the iPhone

1. Install the official **Obsidian** app from the App Store.
2. Open it and choose **Create new vault** → **Set up Sync** → **Use iCloud**.
3. Choose the named existing vault in `iCloud Drive/Obsidian`; do not create a
   new empty vault with the same name.
4. Open a harmless existing note, create one test note on the iPhone, then
   wait for it to appear on the Mac.
5. Edit a different harmless note on the Mac and confirm the iPhone receives
   it. Do not deliberately make simultaneous edits to the same note.

## Boundaries and future migration

- iCloud is the smooth, no-extra-cost option for this Mac and iPhone.
- Do not use Syncthing for the iPhone vault; iOS does not offer a reliable
  official background client.
- When the Windows desktop becomes part of daily notes use, migrate one tested
  copy to a WebDAV/Nextcloud-based sync plan rather than using iCloud Drive on
  Windows.
- Sync is not backup. Keep a separate encrypted backup of the vault outside
  the synced folder.
