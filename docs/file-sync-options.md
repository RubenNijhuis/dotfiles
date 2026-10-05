# File-sync options

Status: **Mac migration applied; Obsidian phone access confirmed by the user on 2026-10-05**.
This confirms mobile access, not a full upload audit or an explicit two-way edit test.
Independent backup work is deferred at the user's request. This does not make
sync a backup. Identify the exact source and destination and obtain approval
before moving existing files or enabling additional cloud-data categories.

## Decision criteria

The chosen system must preserve this same portable tree on every device:

```text
Files/
  00 Inbox/
  10 Projects/
  20 Areas/
  30 Resources/
  40 Archive/
  90 Shared/
```

It should work offline, support macOS, Windows, Linux, iPhone, and iPad where
possible, avoid tying ordinary files to a proprietary format, and include
private personal records in the same purpose-based filing structure. Keep
credentials, technical rollback copies in `~/Private`, developer repositories,
app databases, and device backups out of the synced tree. Synchronization is
not a backup; syncing your own devices does not grant other people access.

## Options

| Option | Best for | Advantages | Costs and limits |
| --- | --- | --- | --- |
| **iCloud Drive only** | Apple-first life with a Windows desktop | Built into macOS, iPhone, and iPad; polished Files integration; Windows has the official iCloud for Windows client. | Linux has no supported native client; iCloud storage is a paid Apple dependency at larger sizes; avoid using it concurrently with another sync engine on the same folder. |
| **Nextcloud/WebDAV** | One first-class folder on macOS, Windows, Linux, and mobile | Open protocols, regular local folders on desktop, server can be self-hosted or hosted by a provider; Nextcloud mobile apps support automatic photo/document uploads. | Requires choosing and maintaining a provider or server; iOS background sync is less invisible than iCloud; setup and conflict handling need a small pilot. |
| **Syncthing** | Direct sync between trusted desktop devices | Free, peer-to-peer, no central storage requirement, strong versioning option, excellent for Mac/Windows/Linux. | No reliable official iPhone background client; devices must be reachable often enough; not a replacement for an off-device backup. |
| **Paid general cloud drive** | Lowest setup effort across desktop platforms | Mature clients and sharing workflows. | Ongoing provider dependence and subscription; less control over data and storage location. |
| **Hybrid: iCloud plus a separate cross-platform store** | Apple convenience without giving up Linux access | iCloud can remain for Photos, Apple app data, and Apple-only material while another service owns ordinary cross-platform files. | Never sync the same live folder with both services; boundaries must stay clear. |

## Recommended paths

### If Apple devices and Windows are the real priority

Use **one iCloud-backed Files tree**, with `~/Files` remaining the stable Mac
entry point through a symlink. Because this whole tree is also the Obsidian
vault, its physical location must be **iCloud Drive/Obsidian/Files**, inside the
actual Obsidian app container, for native iPhone/iPad vault access. On macOS,
that container is `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/`.
Do not create an ordinary folder called Obsidian as a substitute.

Keep the folder **Keep Downloaded** on this Mac, including private personal
records in their normal Areas/Archive categories. Keep technical storage in
`~/Private` and source/build tooling in `~/Developer` local, and leave Desktop
& Documents syncing off to avoid another durable-file root. Desktop and
Downloads remain temporary intake. Do not upload the whole Private folder or
put plaintext password exports, keys, or recovery codes in the Files vault.
Do not relocate browser, mail, password, photo-library, or application databases
manually; Apple app
data uses its own supported iCloud settings.

Windows can access ordinary files through iCloud for Windows, but Obsidian
warns that Windows iCloud vault syncing can cause duplication or corruption.
Do not promise seamless Windows/Linux vault editing or layer a second sync
engine onto this tree. Desktop editing remains a separate later decision.
See [Obsidian's sync guidance](https://help.obsidian.md/sync-notes) and
[Apple's Keep Downloaded instructions](https://support.apple.com/guide/mac-help/mchl1a02d711/mac).

### If every desktop platform is equally important

Keep **`~/Files` local on every desktop** and use **Nextcloud/WebDAV** as the
one sync transport. Each machine points its sync client at its own local
`~/Files`; the folder names and internal structure remain identical. iCloud
continues to handle Apple-specific data only.

### If the goal is maximum independence with a small budget

Use **Syncthing for desktop-only folders**, plus an independent encrypted
backup. Do not select this for the main Obsidian vault until iPhone access has
its own reliable, tested plan.

## Nextcloud in one paragraph

Nextcloud is open-source personal-cloud software. It provides a web interface,
desktop and mobile clients, file sharing, calendars, contacts, and WebDAV—a
standard way for applications to read and write files on a remote server. It
can run on a server you control or be supplied by a hosting provider. Using
Nextcloud does not require self-hosting, but self-hosting adds maintenance.

## Current state and remaining verification

- `~/Files` is the stable entry point, symlinked to
  `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Files`.
- The approved copy was verified on 2026-10-03: all 3,025 non-`.DS_Store`
  files matched by SHA-256, and the directory trees matched. Finder metadata
  changed during copying.
- The original is retained under `~/Private/Migrations/Files-to-iCloud/` as
  `Files.pre-iCloud`. This is a local rollback copy, not another live vault or
  an off-device backup.
- **Keep Downloaded** is enabled; Obsidian reopened its existing `~/Files`
  vault. Finder confirmed the initial upload was in progress, not complete.
- Obsidian's vault chooser now lists only `Files`; the obsolete parent
  `Documents` registration was removed without deleting its folder.
- The user confirmed Obsidian works on their phone on 2026-10-05. A complete
  upload audit and explicit two-way edit test have not been reported; do not
  treat mobile access as proof of either or enable another sync engine here.
- The existing iCloud Drive folder named `Private` is not the local `~/Private`
  and is not part of this migration. Its contents remain uninspected.

## Reconnect on another Mac

Sign into the same Apple Account, enable iCloud Drive, and wait for the actual
Obsidian app container and Files vault to appear. Enable **Keep Downloaded**.
Then recreate the stable path only if it does not already exist:

```sh
icloud_vault="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Files"
test -d "$icloud_vault/.obsidian" &&
  test ! -e "$HOME/Files" && test ! -L "$HOME/Files" &&
  ln -s "$icloud_vault" "$HOME/Files"
```

If the guard fails, inspect the existing path; do not force replacement or
merge two vaults. Open `~/Files` in Obsidian. Account sign-in and personal data
remain outside Nix ownership.

## Obsidian defaults

Nix supplies the application and desktop fonts. Editable vault preferences
live in `Files/.obsidian` and travel with iCloud; do not replace them with
read-only Nix links or commit personal notes, caches, or account state.

- New notes: `00 Inbox`; new attachments: `./Attachments` beside the note.
- New links: relative Markdown links; automatically update links on moves.
- Daily notes: `20 Areas/Personal Administration/Daily Notes`, named
  `YYYY-MM-DD`, using `30 Resources/Templates/Daily Note.md`.
- Templates: `30 Resources/Templates` (Daily Note and Book Report).
- Typography: Open Sans interface/text, 18 px text, FiraCode Nerd Font Mono
  for code. Mobile falls back to available fonts; no custom theme is required.
- Keep deletion confirmation and File Recovery enabled, with system Trash.

Root filing was verified on 2026-10-04: 24 book reports moved into Reading's
Book Reports folder; three review notes and the empty Untitled folder moved
to Inbox. All 27 notes retained their contents; no root Markdown files remain.
Phone access is user-confirmed; an explicit two-way edit test remains unverified.
Settings rollback copies are under
`~/Private/Migrations/2026-10-04-obsidian-settings/`.
