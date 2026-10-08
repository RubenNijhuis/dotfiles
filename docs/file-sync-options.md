# File-sync options

Status: **Mac migration applied; Obsidian phone access confirmed by the user on 2026-10-05**.
This confirms mobile access, not a full upload audit or an explicit two-way edit test.
Independent backup work is deferred at the user's request. This does not make
sync a backup. Identify the exact source and destination and obtain approval
before moving existing files or enabling additional cloud-data categories.

## Execution plan — 2026-10-08

This is a plan, not authorization to upload, bulk-move, delete, publish code,
accept licences, or restart the Mac. Keep one Files tree and one sync owner;
extend the existing setup rather than create another migration framework.

| Order | Work | Completion evidence |
| --- | --- | --- |
| 1. Verify protection | Check iCloud capacity, pending uploads/errors, Keep Downloaded, a Mac -> iPhone -> Mac note test and controlled offline edit. Review local/remote dotfiles state without pushing. | Recorded sync status, passing test and an explicit list of remaining loss-protection gaps. |
| 2. File durable work | Metadata-first review of Documents/Desktop/Downloads, curated creative exports and migration copies. Prepare exact approved destinations in the existing Files tree. | Approved copies verified locally and remotely; unresolved items on a short review list, not a second live vault. |
| 3. Retire leftovers | Start with the pending ~4.72 GiB disposable batch. Compare old Files/Obsidian copies and review browser/code/database recovery material separately. | Every deleted batch approved and verified; retained archives contain identified unique recovery data. |
| 4. Reduce technical stores | Remove identified iOS 17.2/17.5 runtimes through Apple tooling; review simulator cache. Prepare exact Nix generation/root pruning and GC. Inspect OrbStack images/containers/volumes before suggesting removals. | Active Nix generation and needed database/project volumes preserved; actual results measured. |
| 5. Keep it maintainable | Supported Shortcuts/creative-project exports, scoped native Apple sync checks, non-secret settings in existing Nix modules, updated recovery instructions. | Portable exports correctly filed and clear ownership; proposed weekly Inbox/monthly read-only drift reviews. |

Execution boundaries:

- Copy approved cloud-bound files first; verify fidelity and remote availability
  before separately approving removal of originals. Exclude active downloads.
- Fix note links through Obsidian where relevant. Project subfolders belong
  inside a named project, following [the filing rules](personal-file-system.md).
- Private-record policy clarified on 2026-10-08: ordinary legal, employment
  and financial documents may use iCloud-backed Files provided they are not
  accessible to family members. Verify sharing and obtain approval for exact
  cloud-bound records. Never upload plaintext credentials or app databases.
- Preserve unique notes, browser data, code, databases and creative exports until
  coverage is verified. A Migration folder name alone is not a deletion rule.
- npm/pnpm, games and saves stay excluded. No blanket OrbStack prune, disk-image
  deletion or manual Nix-store removal. Xcode licence acceptance belongs to the
  user; the macOS security update/restart remains separately user-scheduled.
- No scheduled deletion, watcher, auto-upload, backup job or automation is
  installed by this plan. Independent encrypted backup remains deferred, not
  completed; keep the loss exposure visible rather than treating sync as backup.
- Revisit Windows/Linux when available. Do not layer another sync engine onto
  the live vault or promise iCloud Obsidian reliability on Windows.

### Read-only audit results — 2026-10-08

| Check | Verified result | Limit / next action |
| --- | --- | --- |
| Capacity and settings | System Settings: 2 TB plan, 720.5 GB used; Drive and Obsidian sync on, Optimize Storage on, Desktop & Documents sync off. | No settings changed; quota displays are not per-file upload proof. |
| Local vault | Finder shows Files and its displayed descendants as Kept Downloaded. Metadata scan: 3,270 regular files, about 3.10 GB logical, no dataless flags, `.icloud` placeholders, symlinks or scan errors. | Local availability confirmed, not complete remote coverage. Phone two-way/offline test remains open. |
| Loose documents | SHA-256 review of 35 intake/output files found 18 with identical filed copies and 17 without one in Files. All three Desktop documents and the reviewed employment outputs have identical filed copies. | Preserve originals pending exact approval; recent downloads, two screenshots and three research outputs need filing review. A matching name alone was insufficient for one downloaded PDF. |
| Original Files copy | Of 2,997 scanned regular files, 2,991 have byte-identical live copies. Six do not: two media files, three Obsidian settings files and an earlier reading index. | Retain pending review; these counts exclude `.git` directories and Finder marker files. No archive was removed. |
| Dotfiles source | A live read-only remote-reference check confirms HEAD equals remote main. Local changed/untracked entries remain. | No commit or push performed. Those changes are not remotely protected. |

The targeted Documents review found 72 files below the local work-output folder;
most are previews or supporting material, not new durable deliverables. The two
reviewed chat workspace folders contained only Git metadata, and the reviewed
legacy documents folder contained no regular files. Creative-app directories
were left app-managed. No private filenames or document contents are stored in
this report; comparisons read locally available files without requesting cloud
downloads. No upload, move, deletion or sync-setting change was made.

Next: approve exact intake copies under the private-record policy below, then
verify remote availability before any separately approved original cleanup.
The phone edit, deletion approvals, licence acceptance and any restart require
user participation; other inspection and small repository work can continue.

### Private records and family access

Family Sharing shares iCloud+ capacity, not access to each member's documents;
everyone must use their own Apple Account. Storage usage can be visible to family
members. Access to files requires separate sharing or access to the account/device.
See [Apple's Family Sharing guidance](https://support.apple.com/en-gb/108783) and
[personal-safety guide](https://help.apple.com/pdf/personal-safety/en_CA/personal-safety-user-guide-en_CA.pdf).

On 2026-10-08, Finder's Shared view showed **0 items** and the Files folder's
context menu offered Share, not Manage Shared Folder. No sharing was found in
these controls; this is not an exhaustive audit of every app's collaboration
settings or proof that nobody else has account/device access. Keep Files and
private-record destination folders unshared; items inside a shared parent inherit
access. The name `90 Shared` does not itself grant anyone access.

Advanced Data Protection was **Off**. Standard iCloud Drive encryption retains
keys with Apple; family privacy is not the same as end-to-end encryption against
the provider. Advanced Data Protection can protect Drive contents with keys held
by trusted devices, but requires a recovery plan and remains deferred. Do not
promise exclusive decryption, change security settings or upload additional
sensitive records under that stronger assumption. See
[Apple's encryption overview](https://support.apple.com/en-gb/102651).

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

### Two-device acceptance test

Use one non-secret note in `00 Inbox`, not a password, real research source,
or private record. Record a Mac marker, confirm it appears in the phone's
existing Files vault, then add a distinct phone marker and confirm it returns
to the Mac. Check the same note after an offline edit and reconnection without
editing it simultaneously on both devices. Mobile access and a placeholder-free
local scan alone do not establish completed uploads or two-way sync.

For Apple Calendar, choose a specific iCloud calendar as the new-event default
instead of “Selected calendar”. Use a clearly labelled, non-sensitive test
event with no attendees to verify appearance and notifications on both devices;
do not alter existing appointments. Browser Sync should not become a second
password store alongside Apple Passwords: review bookmarks/tabs/extension
choices in the actual signed-in browser, not by copying profile databases.

### Restore the stable Mac path

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
