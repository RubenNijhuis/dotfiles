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

`~/Private` is the separate, local-only holding area for sensitive files that
must never enter ordinary file synchronization: identity scans, password
manager exports, recovery codes, and confidential exports. It is owner-only
on Unix systems, but that is not encryption; it must still be included in an
encrypted backup plan and kept out of cloud-sync roots.

## Folder rules

| Folder | Put here | Do not put here |
| --- | --- | --- |
| `00 Inbox` | Unsigned forms, scans, downloads, and material awaiting a decision | Long-term storage; process it regularly |
| `10 Projects` | Active, time-bounded efforts with a clear outcome | Git repositories; put their source in `~/Developer` |
| `20 Areas` | Finance, health, legal, household, career, learning, and other continuing responsibilities | Temporary project drafts |
| `30 Resources` | Reference PDFs, manuals, reusable assets, research, reading | The only copy of a critical record |
| `40 Archive` | Completed projects and inactive reference material, preserving its prior structure | Disposable clutter |
| `90 Shared` | Intentionally shared material with a clearly selected sync policy | Secrets, passwords, device backups, or application databases |

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
DOTFILES_PRIVATE_ROOT    # defaults to ~/Private; never sync this root
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

1. **Working copy** — the local `~/Files` folder.
2. **Sync** — an intentionally selected transport, initially one small test
   folder rather than the entire history.
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
| Ordinary active documents in `~/Files` | local working copy | Syncthing between trusted personal devices |
| Large media and archives | selected subfolders | opt-in Syncthing replication only where storage allows |
| Secrets and private configuration | encrypted source only | `sops` + `age` through Git, introduced after recovery keys are planned |
| Recovery copies | encrypted backup repository | Restic to local and offsite destinations |
| App databases, caches, browser profiles, VM data | device-local | application-supported sync only, if needed |

The first sync pilot should be one small, low-risk folder—not the whole home
directory or all of `~/Files`. Enable Syncthing staggered versioning before
adding real work. After testing offline edits, a conflict, and recovery from a
deletion, expand one folder at a time. Use Restic independently: sync makes
files available, while a tested encrypted backup makes them recoverable.

For Windows, run Syncthing against the native `C:\Users\<you>\Files` tree;
WSL accesses it at `/mnt/c/Users/<you>/Files` when Windows applications need
the same documents. Keep Linux project repositories and package data outside
that mounted tree.

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
4. **Private:** retain as a local-only boundary until an encrypted backup and
   recovery procedure exists. It is never a general Syncthing folder.

Before any irreversible cleanup, create a mapping manifest and verify copies
or hashes for duplicated material. Former-employer and legal material need an
explicit retention decision; they are not part of an automated cleanup.

## Adoption sequence

1. Run `make files-init` on each device. It creates the empty structure and
   changes nothing else.
2. Point the file manager sidebar at `~/Files` and keep Downloads as a source
   for `00 Inbox`, not as permanent storage.
3. Inventory existing folders by category and move only copies or clearly
   classified groups, verifying each move before deleting an original.
4. Pilot Syncthing on one small folder with versioning enabled; test a restore
   and a conflicting offline edit before expanding it.
5. Add Restic encrypted, versioned backups before relying on the new
   structure; verify with an actual restore into a temporary folder.

No mass move or cloud migration is part of the initializer.
