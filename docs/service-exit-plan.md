# Service exit plan

The goal is not to abandon useful services overnight. The goal is to avoid
being trapped by any one company: keep data exportable, prove an alternative
works, and leave only when the alternative is reliable.

This register is deliberately conservative. **Confirmed** means you mentioned
the service. **Verify** means it appears in the old application inventory but
does not prove that you use or pay for it.

## Exit rules for every service

Before cancelling a paid service, record:

1. What data it holds and whether that data is the only copy.
2. An export made and opened successfully in the replacement software.
3. The replacement's backup and recovery method.
4. A 30-day parallel-use period (90 days for photos, documents, or passwords).
5. The cancellation date and a final offline archive.

Never put service credentials, exports containing private data, or recovery
codes into this repository.

## Confirmed service

| Service | Dependency | Open / self-owned direction | Migration plan | Current status |
| --- | --- | --- | --- | --- |
| iCloud | Device backup, Photos, Drive, Keychain, Mail/Calendar, or subscriptions—exact scope to confirm. | Split the dependency by data type: local encrypted backups; standard IMAP/CalDAV mail and calendar; a non-Apple file-sync target; a separate password vault. | Inventory the enabled iCloud features; export one category at a time; run the replacement alongside iCloud; retain iCloud where Apple-device backup remains materially better. | Plan only; no data or account access performed. |

Leaving iCloud completely may be neither practical nor desirable while using
Apple hardware. The durable win is making it a convenience layer, not the
only place that holds irreplaceable data.

## Services suggested by the old app inventory — verify before planning an exit

| Service / app | Likely dependency | Open alternative or exit direction | First safe action |
| --- | --- | --- | --- |
| Google Chrome / Google account | Browser sync and possibly Google data | Firefox Sync; standard IMAP/CalDAV where applicable | Export browser data, make Firefox the daily browser for 30 days. |
| Dropbox | File sync | Syncthing for device-to-device files; Nextcloud/WebDAV only if a hosted sync service is justified | Identify the folders and create an offline backup before moving one non-critical folder. |
| Obsidian Sync | Notes sync | Keep Markdown vault; evaluate Logseq and a standard sync method | Trial a copy of one small vault; do not migrate the live vault yet. |
| Spotify / Sonos | Streaming and speaker control | Keep as optional entertainment; use local files with VLC/Strawberry where that suits | Export playlists/library metadata; decide whether streaming itself is worth retaining. |
| Figma / Affinity | Design source files and workflow | Krita, Inkscape, GIMP, Blender; SVG/PNG/PDF source formats | Export active projects to open formats and trial one current task. |
| Slack / Discord / WhatsApp | Communities and existing contacts | Signal for private messaging; Element/Matrix for communities you control | Do not migrate a community unilaterally; move personal conversations only where contacts agree. |
| Linear | Project data | Plain Markdown/Git issues, Vikunja, or a hosted open-source tracker | Export personal projects and trial a small project elsewhere. |
| LM Studio / other AI service | Local-model workflow or paid API | Ollama plus locally stored models; keep cloud APIs explicitly opt-in | List models, prompts, and API use; no need to remove a local tool before replacement works. |
| Steam / Epic | Purchased games, multiplayer and anti-cheat | Linux + Steam/Proton; Heroic; DRM-free stores when practical | Keep launchers on the gaming desktop only; do not expect a complete immediate exit. |

## Decisions still needed

This repository cannot determine subscriptions or inspect account data. To
complete this register, add the paid services you actually use (including
storage, email domain, music/video, AI, design, productivity, VPN, and
mobile-phone services) and mark each as **keep**, **reduce**, **replace**, or
**leave**. Each then gets the same evidence-backed exit plan above.
