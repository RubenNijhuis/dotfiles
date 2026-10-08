# Personal file system

## Purpose

Every personal computer uses the same logical home for documents and files:

```text
~/Files
├── 00 Inbox
├── 10 Projects
├── 20 Areas
├── 30 Resources
├── 40 Archive
└── 90 Shared
```

This is a compact PARA-style system: projects are finite outcomes; areas are
ongoing responsibilities; resources are reference material; archive is
inactive material. The numbered prefixes make the order stable in Finder,
Explorer, and Linux file managers without requiring a particular application.

`~/Developer` remains for source repositories, build artifacts, and local
tooling. It is not a document store. Large media libraries, virtual machines,
downloads, caches, application support folders, and backups also stay outside
`~/Files` unless they are deliberate, curated assets.

Private personal records also belong in the iCloud-backed `~/Files` tree,
classified by purpose: legal and identity documents in `20 Areas/Legal & Records`,
financial records in `20 Areas/Finance & Business`, employment records in
`20 Areas/Career & Employment`, and historical material in `40 Archive`.
Sensitivity alone is not a reason to create a device-only document library.
The user reaffirmed this on 2026-10-08, conditional on no family access. Keep
these folders unshared and review exact uploads; see the
[family-access and encryption boundary](file-sync-options.md#private-records-and-family-access).

`~/Private` remains local technical storage for credential exports, keys, and
migration/rollback material, not the canonical home for personal records.
Do not upload that entire folder: it can contain secrets and duplicate vaults.
Owner-only permissions are not encryption; recovery copies need a separate
encrypted backup plan. Passwords and passkeys belong in Apple Passwords.

## Folder rules

| Folder | Put here | Do not put here |
| --- | --- | --- |
| `00 Inbox` | Unsigned forms, scans, downloads, and material awaiting a decision | Long-term storage; process it regularly |
| `10 Projects` | Active, time-bounded efforts with a clear outcome | Git repositories; put their source in `~/Developer` |
| `20 Areas` | Finance, health, legal, household, career, learning, and other continuing responsibilities | Temporary project drafts |
| `30 Resources` | Reference PDFs, manuals, reusable assets, research, reading | The only copy of a critical record |
| `40 Archive` | Completed projects and inactive reference material, preserving its prior structure | Disposable clutter |
| `90 Shared` | Intentionally shared material with a clearly selected sync policy | Secrets, passwords, device backups, or application databases |

Syncing between your own devices is not sharing with other people. Private
records stay in their normal category, not `90 Shared`; do not enable public
links or other people's access without explicit approval.

Use dates as `YYYY-MM-DD` when chronology matters, e.g.
`2026-08-31 travel-insurance-policy.pdf`. Keep names human-readable; do not
invent a complicated tagging taxonomy.

## Cross-platform contract

The shell exports the following portable locations:

```text
DOTFILES_FILES_ROOT      # defaults to ~/Files
DOTFILES_FILES_INBOX
DOTFILES_FILES_PROJECTS
DOTFILES_FILES_AREAS
DOTFILES_FILES_RESOURCES
DOTFILES_FILES_ARCHIVE
DOTFILES_FILES_SHARED
DOTFILES_PRIVATE_ROOT    # defaults to ~/Private; local credentials/technical rollback
```

On macOS and Linux, use the default `~/Files`. On Windows, use
`C:\Users\<you>\Files`. WSL should normally use its own `~/Files` and sync it
through the chosen mechanism; point `DOTFILES_FILES_ROOT` at a mounted Windows
folder only for documents that genuinely need Windows applications. This
avoids the performance and permission surprises of making all WSL work live
under `/mnt/c`.

## Sync and backup boundary

Synchronization is not backup. The eventual system has three independent
layers:

1. **Working copy** — `~/Files`, kept downloaded on this Mac.
2. **Sync** — iCloud Drive for the current Mac/iPhone/iPad setup, using the
   actual Obsidian app container and one Files tree.
3. **Encrypted backup** — a versioned backup kept separately from the sync
   provider.

Open formats come first: Markdown/text, PDF, OpenDocument, CSV, PNG/JPEG,
SVG, FLAC/WAV, and source files. Keep vendor-native documents only alongside
an exported portable copy when possible.

Do not synchronize passwords, SSH keys, recovery codes, application caches,
or raw iCloud/Photos libraries through this tree.

## Recommended cross-device design

Use one owner and one transport for each kind of data:

| Data | Canonical owner | Cross-device method |
| --- | --- | --- |
| Nix, dotfiles, scripts, templates | Git repository | Git clone/pull; never a file-sync folder |
| Documents, notes, and curated media in `~/Files` | one iCloud Drive/Obsidian/Files tree | iCloud Drive on Apple devices; stable `~/Files` symlink on Mac |
| Passwords and passkeys | Apple Passwords | supported iCloud Keychain sync; never plaintext files or Nix |
| Private personal records | purpose-based folders in `~/Files` | same iCloud tree; no public or shared access by default |
| Keys, plaintext credential exports, technical rollback | local `~/Private` or app-owned storage | secure provisioning/encrypted recovery, not ordinary file sync |
| Recovery copies | independent encrypted backup | deferred; iCloud and the local migration copy are not substitutes |
| App databases, caches, browser profiles, VM data | device-local | application-supported sync only, if needed |

See [file-sync options](file-sync-options.md) for the current handoff, reconnect
instructions, and Windows/Linux limitations. Do not run two sync engines on
the same live vault. Keep repositories and package data outside synced files.

## Current consolidation queue

The initial audit found that this structure should be adopted by classification,
not by one broad move:

1. **Desktop and Downloads:** treat as intake. Classify documents into
   `00 Inbox` first; do not bulk-move archives, duplicate download variants, or
   media until they are reviewed.
2. **Documents:** move only clearly personal, durable documents into the
   appropriate `Projects`, `Areas`, `Resources`, or `Archive` category.
   Leave app-owned folders in place until the owning application is identified.
3. **Developer:** keep active repositories in `~/Developer` and use Git for
   synchronization. Classify old non-repository material before moving it into
   `~/Files/40 Archive`; do not sync build outputs or dependency directories.
4. **Private:** classify durable personal documents into the normal synced
   Files categories after reviewing exact targets. Keep credential exports,
   keys, and technical migration copies local; do not sync this root wholesale.

Before any irreversible cleanup, create a mapping manifest and verify copies
or hashes for duplicated material. Former-employer and legal material need an
explicit retention decision; they are not part of an automated cleanup.

## Adoption sequence

1. On another Mac, reconnect the existing iCloud Files tree first. Use
   `make files-init` for a new local tree or missing structural folders only;
   it does not configure sync.
2. Point the file manager sidebar at `~/Files` and keep Downloads as a source
   for `00 Inbox`, not as permanent storage.
3. Inventory existing folders by category and move only copies or clearly
   classified groups, verifying each move before deleting an original.
4. Verify the initial iCloud upload and mobile note editing in both directions.
   Keep the Mac copy downloaded; Windows/Linux editing needs a separate plan.
5. When backup work resumes, add independent encrypted, versioned backups
   and verify an actual restore into a temporary folder.

No mass move or cloud migration is part of the initializer.
