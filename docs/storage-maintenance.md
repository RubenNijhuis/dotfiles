# Storage maintenance

Run the read-only size review from the repository:

```sh
make storage-audit
```

The tool reports disk space available on the macOS Data volume and allocated
storage for a fixed set of app data, package caches, development tools, the
Developer directory, and temporary files. It does not
launch package managers, inspect file contents, hash files, delete data, run
garbage collection, connect accounts, or request cloud downloads. It prints only
aggregate target names and sizes. App locations may change after updates;
`missing` means the configured target was not found.

Each directory has a 30-second limit. Use `--timeout 60` for a slow directory.
`partial` means some descendants were unreadable, so the reported size is
incomplete. `denied`, `timeout`, and other unavailable states do not establish a
zero size. Symlink targets and cloud-provider directories are skipped.

OrbStack image files are measured by allocated blocks, so sparse images are not
reported at their larger logical capacity. Directory measurements use `du -skPx`,
which does not follow symlinks, stays on the target filesystem rather than
traversing mounted runtimes, and counts hardlinks once within each invocation.
Separate rows may overlap, and APFS clones or snapshots may share storage. Do not
add all rows together or treat their sizes as guaranteed cleanup savings.

To retain a baseline outside the repository, redirect JSON to a local report path
you have chosen. Reports include the configured root paths and your username;
review them before sharing. The tool itself writes no files.

```sh
python3 ops/storage-audit.py --json > /private/tmp/storage-baseline.json
python3 ops/storage-audit.py --compare /private/tmp/storage-baseline.json
```

Changes are shown only when both measurements for the same path are complete.
Use `--path` to inspect an explicit directory or file without running the default
inventory; it can be repeated:

```sh
python3 ops/storage-audit.py --path /private/tmp --timeout 15
```

## Routine

- Weekly: review the size table and intake folders. Give durable files a clear
  destination; modification dates alone do not prove that a file is unused.
- Monthly: review package and application growth. Prepare exact cleanup targets,
  explain the tradeoff, and obtain approval before pruning or deleting. Prefer
  the owning app or package manager's supported cleanup mechanism.
- Quarterly: review completed projects and archive folders for cloud-only
  storage. Verify sync and backup first, keep active documents available offline,
  and use the cloud provider's Remove Download action for local eviction.

Keep credentials and technical/local-only recovery material in `~/Private`.
Ordinary private personal records may use unshared, purpose-based Files folders
under the [family-access policy](file-sync-options.md#private-records-and-family-access).
Do not relocate browser or mail
profiles, creative-app databases, game saves, or media libraries blindly. Cloud
sync propagates deletion, so local eviction and deletion require different
decisions. Duplicate cleanup requires an exact reviewed file set and a chosen
canonical copy. This tool does not infer unused files or perform duplicate
cleanup. No scheduled deletions or automatic pruning are installed.

## Cleanup review — 2026-10-07

The Mac had about 168 GiB available; there is no urgent reason to remove
application data. The selected complete measurements were:

| Exact target | Allocated | Decision |
| --- | --- | --- |
| `~/.npm/_cacache` | 1.71 GiB | Skipped by user; leave intact. |
| `~/.cache/pnpm` | 2.69 GiB | Skipped by user; leave intact. |
| `~/.cache/uv` | 493 MiB | Approved cleanup completed; future use can recreate downloads. |
| `~/Library/Caches/Homebrew/downloads` | 771 MiB | Approved cleanup completed; installed apps were untouched. |
| `~/Library/Developer/CoreSimulator/Caches` | 5.54 GiB | Simulator cache, mostly under `dyld/25F84`; review through Apple tooling. |
| `~/Library/Developer/CoreSimulator/Devices` | 4 KiB | No meaningful device-data savings in this measurement. |
| `/Library/Developer/CoreSimulator/Images` | 13.68 GiB | Runtime images; keep until exact installed runtimes are identified and approved. |

Simulator inventory is blocked: the selected developer directory is Command
Line Tools, and using the installed Xcode explicitly reports an unaccepted
license. Do not switch the global developer directory or accept legal terms
automatically. Review/accept the license yourself only if you want to use
Xcode, then inventory runtimes with `simctl` or Xcode Settings > Components.
The image registry identifies iOS 17.2 (21C62) and iOS 17.5 (21F79). That gives
us exact review candidates, but their live availability/mount state still needs
Apple's tooling. The runtime-preference map is not an installed-runtime inventory.
Do not manually delete the whole CoreSimulator directory or mounted runtimes.

After approval, `~/.cache/uv` and `~/Library/Caches/Homebrew/downloads` were
removed while their owners were idle, then verified absent. Their measured
allocation before cleanup was about 1.23 GiB together; this is not a guarantee
of the same increase in free space on a concurrently used APFS volume. The
downloads can be recreated, but their previous offline copies are gone.

`~/.npm/_cacache` and `~/.cache/pnpm` were initially deferred for active project
jobs; the user then explicitly chose to **skip both**. Leave them intact; do not
clean them later under the earlier approval. No simulator data was removed.
Game libraries, CrossOver bottles, OrbStack images, messaging media and browser
profiles are not package-cache cleanup targets. The three retired browsers'
profiles were separately archived with approval; see the application catalog.

## Follow-up cleanup — 2026-10-07

The follow-up review found these exact candidates, without opening their data:

- After approval, VS Code's `anthropic.claude-code` extension was uninstalled
  and verified absent from the installed-extension list. `~/.claude` (12 KiB)
  was moved to `~/Private/Migrations/2026-10-07-claude-retirement/claude` and
  verified absent at its original path. Its contents were not inspected. Do not
  close or restart active editor windows solely for cleanup; a running extension
  host may need a user-chosen window reload to unload already-loaded code.
- `/Library/LaunchAgents/us.zoom.updater.plist` and
  `/Library/LaunchAgents/us.zoom.updater.login.check.plist` point to the absent
  `/Applications/zoom.us.app` updater and are not loaded in this user's domain.
  `/Library/LaunchDaemons/com.oracle.java.Helper-Tool.plist` is a broken symlink;
  its service was not loaded. All three entries were archived after administrator
  authorization on 2026-10-07, preserving `LaunchAgents/` and `LaunchDaemons/`
  under `~/Private/Migrations/2026-10-07-service-retirement/`. Completion was
  rechecked on 2026-10-08: the original paths are absent and all three archived
  entries remain. Restoring system entries requires administrator access.
  The working Zoom app/daemon and installed Java updater were untouched.
- After approval, all 21 backups below were moved into
  `~/Private/Migrations/2026-10-07-pre-nix-consolidation/` with relative paths
  preserved. Every move's filesystem identity and the original live Nix link
  were verified. `shell/cmux.sh.pre-nix` was itself an absolute Nix-store
  symlink: the original link is preserved, plus a standalone
  `shell/cmux.sh.pre-nix.payload` copy for rollback after later garbage collection.
  Backup contents were not inspected; the payload was copied directly.

Exact backup paths relative to `~/.config/`:

```text
starship.toml.pre-nix
shell/path.sh.pre-nix
shell/functions.sh.pre-nix
shell/aliases.sh.pre-nix
shell/cmux.sh.pre-nix
shell/exports.sh.pre-nix
lazygit/config.yml.pre-nix
yazi/keymap.toml.pre-nix
yazi/theme.toml.pre-nix
yazi/yazi.toml.pre-nix
tmux/tmux.conf.pre-nix
eza/theme.yml.pre-nix
btop/btop.conf.pre-nix
btop/themes/tokyo-night-custom.theme.pre-nix
bat/config.pre-nix
bat/themes/tokyonight_night.tmTheme.pre-nix
sesh/sesh.toml.pre-nix
nvim.pre-nix
atuin/config.toml.pre-nix
cmux/cmux.json.pre-nix
ripgrep/ripgreprc.pre-nix
```

The aggregate application rollback archive is 7.82 GiB, including previously
retired apps and preserved profiles. It is not an off-device backup or free
space; keep it until the replacements have been used and permanent deletion
of an exact subset is separately approved. `.dotfiles-backup` is only 160 KiB,
and all `~/Library/Logs` measured 64.61 MiB: neither justifies blanket purging.
`.m2` is empty; `.gem` (27.73 MiB) and `.bun` (55.52 MiB) remain unclassified
developer state, not automatic deletion targets. The inspected `.asdf`,
`.rustup`, `.dotnet`, `.expo`, `.gradle`, `.cocoapods`, and `.hyper_plugins`
folders are already absent. Google Keystone's two plists are empty dictionaries;
leave these placeholders and the working GoogleUpdater alone. Preserve Pioneer
hardware tools, Steam, OrbStack and Nix services.

Nix's `nix-store --gc --print-dead` inventory reported 18,968 unreferenced store
paths. No store paths were collected; the inventory itself tidied one stale
automatic GC-root link to the absent Home Manager `gcroots/new-home` path.
This is not a reclaimable-size estimate. The aggregate store size timed out,
and Trash inspection was denied; neither is zero. Do not empty Trash or remove
Nix generations based on this count. The permission-checklist generation activated
successfully on 2026-10-07 and was verified on 2026-10-08: `/run/current-system`
points to `pqjarbnrkfxhb691wyslw1jcv3jyy9dn-darwin-system-26.11.4cff07d`, and
`~/.config/dotfiles/macos-permissions.txt` resolves to a Home Manager store file.
This checklist records policy; it does not automatically grant permissions.
Supported Nix garbage collection still requires separate approval: collected
builds may need downloads or rebuilding. Keep rollback generations and do not
manually delete store files.

The 2026-10-08 follow-up found no further missing absolute executables or broken
plist links in `/Library/LaunchAgents`, `/Library/LaunchDaemons`, and this user's
`~/Library/LaunchAgents`. This is a path-integrity check, not proof every service
is needed or an exhaustive background-process audit.

Verification on 2026-10-08: all maintenance checks passed, and the application
audit found no duplicate bundle IDs in its inspected application directories.
The security check confirmed Screen Sharing/SSH disabled with no listeners on
the reviewed remote-access ports. It failed only the macOS-update check: this
Mac still runs 26.5.2, which predates Apple's Screen Sharing fix in 26.6.1.
The operating-system update and restart remain pending; no update was installed
by this cleanup. The completed one-use administrator script was removed from
its temporary directory; all migration archives remain intact.

## Simulator and rollback retirement review — 2026-10-08

The user wants simulator data and redundant rollback copies retired. Exact
permanent-deletion batches still need confirmation; no blanket migration-folder
purge is authorized by this review.

| Measured target | Allocated | Classification |
| --- | --- | --- |
| CoreSimulator runtime images | 13.68 GiB | iOS 17.2/17.5 candidates; removal blocked by Xcode's unaccepted licence. |
| User CoreSimulator cache | 5.54 GiB | Rebuildable simulator data; use Apple tooling, not a manual whole-tree purge. |
| Archived OrbStack/Zoom/CrossOver app bundles, retired Arc/Brave/Pale Moon bundles and their Remnants | 3.29 GiB | Exact disposable batch presented for permanent-deletion confirmation; current apps and archived profiles excluded. |
| Archived .NET/nvm runtimes | 1.43 GiB | Same proposed batch; reinstalls may require downloads. npm/pnpm untouched. |
| Retired-browser Profiles | 4.54 GiB | App-owned historical browsing data; separate review, not merely installer rollback. |
| Original Files-to-iCloud tree | 2.38 GiB | Personal-file copy; preserve until current coverage/upload is verified. |
| Zen profile backups | 296.81 MiB | Settings and browsing-data backups; separate review. |
| Database archive | 182.20 MiB | Potential unique database content; preserve. |
| Code Recovery | 42.24 MiB | Historical code snapshots; preserve pending repository coverage checks. |
| Obsidian vault backups | 6.47 MiB | All 46 note/attachment files in each of the three snapshots match live copies; settings/manifest excluded. Retain until exact deletion approval. |
| Resolve Exports | 264 KiB | Creative-project export, not an installer leftover; preserve. |

The proposed disposable batch is approximately 4.72 GiB. Simulator images and
cache add approximately 19.22 GiB of measured opportunity, not guaranteed free
space. APFS sharing and concurrently running apps affect actual savings.
The six small dated retirement/settings folders in `~/Private/Migrations/`
together occupy only about 0.4 MiB; folder-count clutter is not disk pressure.

The Obsidian snapshot comparison used SHA-256 on locally available regular
files, excluding `.obsidian`, Git metadata, Finder markers and the generated
manifest. All three snapshots have complete note/attachment coverage in the live
Files tree. Settings and historical recovery state remain a separate retention
decision; nothing was deleted or uploaded by this comparison.

There are 54 system-generation links; generation 54 is active. Pruning the
older 53 and collecting unreferenced Nix builds is another distinct destructive
batch. No reclaimable-size estimate has been established, and no generation or
store object was removed. Use supported Nix profile/GC tools only after exact
approval; preserve the active generation and private data.

Apple documents runtime deletion through Xcode's component controls:
<https://developer.apple.com/documentation/Xcode/downloading-and-installing-additional-xcode-components>.
The explicit installed-Xcode `simctl` invocation still reports an unaccepted
licence; the agent cannot accept that legal agreement for the user.
