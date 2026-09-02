# File-sync options

Status: **parked decision**. Do not move `~/Files` or configure a second sync
service until one option below is explicitly selected and a verified backup is
available.

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
possible, avoid tying ordinary files to a proprietary format, and keep
`~/Private`, developer repositories, app databases, and device backups out of
the synced tree. Synchronization is not a backup.

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

Use **one `iCloud Drive/Files` folder** as the canonical ordinary-file tree.
Keep `~/Private` and `~/Developer` local. Do **not** enable iCloud's Desktop &
Documents feature: it relocates macOS system folders and makes later migration
harder. Linux receives read-only web access or a deliberate later migration.

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

## Current state and safe next action

- `~/Files` remains local and is the current canonical path on this Mac.
- The Obsidian vault is at `~/Files/30 Resources/Knowledge/Ruben Knowledge`.
- No cross-device file sync is configured yet.
- Before any migration: make an independent verified backup, move one small
  pilot folder, test offline edits and conflict recovery, then expand in stages.

