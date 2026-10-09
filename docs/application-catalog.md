# Application catalog

Nix is the first-choice package owner. Use Homebrew only for a documented
macOS exception; keep account data and application databases outside Git.
This is an installation policy, never authorization to uninstall an app.

## Everyday defaults

| Task | Preferred app | Configuration boundary |
| --- | --- | --- |
| Browser | Zen Twilight on this Mac; Zen on other desktops | Nix supplies the desktop browser. Sessions, extensions, passwords, and supported browser sync remain app-owned. |
| Email | Thunderbird | Nix supplies telemetry-off and changeable Open Sans/density/GPC defaults without managing profiles. IMAP/OAuth accounts remain device-owned. Never synchronize its profile database. Apple Mail may remain the iPhone client. |
| Calendar | Apple Calendar on Apple devices; Thunderbird elsewhere | Keep one source per calendar. This Mac currently has iCloud and local calendars; Google is not a mandatory provider. Configure accounts and alerts separately from Nix. |
| Passwords | Apple Passwords / iCloud Keychain | The current single source of truth. Credentials, passkeys, recovery codes, and exports never belong in Nix or this repository. |
| Notes | Obsidian, plain Markdown under `~/Files` | Vault settings and templates travel with the existing iCloud Files vault; do not replace them with read-only Nix links. Nix supplies the matching Web Clipper import template. Mobile access is user-confirmed; a controlled two-way/offline check is separate. Windows/Linux sync remains a separate decision. |
| Code | VS Code; Neovim in the terminal | Nix owns shared settings and Neovim plugins. VS Code extension IDs are declared, but their versions remain marketplace-managed. |
| Terminal | cmux on this Mac; native terminal elsewhere | Shell, Git, prompt, and navigation are shared; the terminal windowing app is host-specific. |
| Private messaging | Signal | Sign in/link each device through the app. Keep its database local. |
| Fonts | Open Sans; Fira Code Nerd Font | Nix supplies desktop fonts; mobile apps may need fallbacks. |

A desktop app being installed does not mean accounts, mobile sync, recovery,
or notifications are configured. Verify those separately. AI access is also
a separate, explicit permission; it does not follow from choosing a calendar
or notes application.

## Lean, composable capabilities

| Capability | Declared portable tools | Native apps when needed |
| --- | --- | --- |
| Core | Git, shell, search/preview, navigation, terminal tools, Neovim | None required for a headless host. |
| Development | Nix maintenance, Node 24/pnpm, formatters, GitHub CLI, Jujutsu, selected language servers | VS Code; OrbStack on this Mac. Pin other runtimes and package-manager requirements in each active project. |
| Writing | Pandoc, Typst, Vale, LanguageTool | Obsidian for notes/drafts; a document editor only when its format or workflow is needed. |
| Design | Image/SVG optimization; Krita and RawTherapee on supported Linux hosts | Krita for illustration; RawTherapee for photos; existing Affinity/Figma remain optional, not a portable requirement. |
| Media | FFmpeg, SoX, yt-dlp as optional supporting tools | HandBrake for file-to-file conversion; DaVinci Resolve for video and its audio workflow. Audacity for standalone audio editing if needed. No serious music-production stack by default. |
| Gaming | Linux gaming capability; occasional Mac gaming retained | Steam, Heroic, Prism as actually used. Do not remove Mac games just to make the laptop baseline smaller. |
| Leisure | Optional Spicetify CLI and reusable theme | Spotify and other account/hardware-specific players stay app-owned. |

Capabilities are additive, not competing complete installers. The Mac imports
core, developer, desktop apps, browser, writing, and leisure. WSL remains
command-line only; its GUI apps and games run natively on Windows. The Linux
desktop adds its gaming capability. Design/media modules are opt-in rather
than installed everywhere. See [Nix transition](nix-transition.md) for exact
host composition.

## Package exceptions

| Exception file | Purpose |
| --- | --- |
| `brew/Brewfile.design` | Krita and RawTherapee where the pinned Nix package lacks suitable Apple Silicon support. |
| `brew/Brewfile.media` | HandBrake while the pinned Mac Nix package is unsuitable. |
| `brew/Brewfile.gaming` | Prism Launcher and its required Java runtime on this Mac. |
| `brew/Brewfile.services` | Deliberately selected local-service exception, not a global server stack. |
| `brew/Brewfile.security` | Newer Mac pinentry; GnuPG itself is Nix-owned. |

The personal-laptop profile selects design/media exceptions to restore the
creative apps already installed here. Minimal and other machines remain lean.
On 2026-10-05 a real RawTherapee Nix build failed on its Linux-only `libselinux`
dependency despite permissive package metadata; HandBrake is marked broken on
Darwin and Krita is Linux-only. Keep those exceptions until builds actually work.

OneMenu is a manual Mac-only exception: no suitable package was found in the
pinned Nix set or Homebrew during its audit. Keep it; record a new package
owner only after verifying a replacement. Reassess exceptions when updating
the Nix pin, rather than importing the entire installed Homebrew inventory.

## Native restore boundaries

Read-only inventory on 2026-10-05, excluding Apple system apps and game-library
launchers. This is a recovery/ownership list, not an uninstall request:

| Area | Existing manually managed applications |
| --- | --- |
| Communication | WhatsApp, Slack, Discord; the app named ChatGPT is retained as-is pending identity review |
| Creative work | DaVinci Resolve and Blackmagic utilities, Affinity, Figma, rekordbox and Pioneer updater, Processing |
| Leisure | Spotify, Steam; retain existing games and saves |
| Platform and legacy tooling | Xcode, Python 3.11 GUI tools, OneMenu |
| Alternative browsers | Chrome remains for compatibility; Zen Twilight remains preferred. Arc, Brave and Pale Moon app bundles were retired on 2026-10-07. |

Zoom and CrossOver are now declared in this Mac's Nix layer; neither is added
to Linux, WSL, or the portable core. The pinned Zoom package needs a small
override to preserve its vendor signature: stripping the packaged binaries
invalidates it. Verify signed bundles outside the restrictive tool sandbox,
which can produce false signature failures for otherwise valid applications.

Do not make a huge installer by assuming every old app is still wanted. Use
this restore matrix for the retained native apps, without copying their databases:

| Apps | Restore path / reason not in the Nix baseline |
| --- | --- |
| WhatsApp, Slack, Discord | Official app installer/updater for now: installed versions 26.39.21, 4.51.191, 0.0.414 are newer than the pin's 2.26.31.27, 4.51.180, 0.0.413. Recheck at the next Nix update; do not downgrade. |
| App named ChatGPT | Its bundle ID is `com.openai.codex`. Preserve this actual app and use its supported updater until a matching replacement is verified; filename alone does not establish identity. |
| Spotify | Official writable installation (currently 1.3.3.264); Spicetify must not patch a Nix-store app. The pin is also older (1.2.98.301). |
| Steam | Native Mac Steam installer; the pinned Steam derivation is not a supported Darwin package. Game saves and Cloud status are separate. |
| Resolve / Blackmagic tools | [Blackmagic support installers](https://www.blackmagicdesign.com/support/); the pinned Resolve is Linux-only. Restore exported projects and source media separately. Companion tools are installer components, not independent baseline apps. |
| Affinity / Figma | Official vendor installers; no matching native Mac package in the pin. `figma-linux` is not the Mac client. [Figma downloads](https://www.figma.com/downloads/). |
| rekordbox / Pioneer tools | [rekordbox installer](https://rekordbox.com/en/download/) and hardware-specific vendor updates. Keep libraries/licenses outside Nix; do not silently replace version 6 with a newer major version. |
| Processing / Python 3.11 GUI tools | Retained legacy vendor installs, not current global runtime requirements. The pinned Processing is Linux-only; put future Python environments in their own code projects. |
| Xcode / OneMenu | Xcode via Apple's supported installer/App Store; [OneMenu vendor installer](https://coffeebreak.software/one-menu/). No verified Nix equivalent for OneMenu. |
| Chrome | Retained for compatibility, not the default. Its installed build is newer than the pin; recheck before migrating. Never import browser profiles into Nix. |

This inventory is not a claim that each app is needed or that it is fully
recoverable. Licenses, sign-ins, media libraries, and app-local work need their
own supported recovery paths. Re-evaluate temporary version exceptions when
updating the Nix pin rather than adding bespoke overrides for every GUI app.

On 2026-10-07 the approved `/Applications/Arc.app`, `/Applications/Brave Browser.app`,
and `/Applications/Pale Moon.app` bundles were moved to
`~/Private/System Migration/Application Archives.noindex/2026-10-07-retired-browsers/`.
Their bundle IDs/versions were verified in the archive and they no longer appear
in the active app inventory. The app bundles are recoverable; this archive does
not free their storage. After separate approval, the three profiles formerly at
`~/Library/Application Support/{Arc,BraveSoftware,Pale Moon}` were moved into
the archive's owner-only `Profiles/` folder. The original folders are absent;
each move preserved the directory's filesystem identity. The six reviewed
cache/preferences remnants were subsequently moved into the archive's
owner-only `Remnants/` folder and verified absent from their original locations.
Zen, Safari and
Chrome remain installed. No browser databases were inspected or imported into
this repository.

The approved Homebrew exit batch completed on 2026-10-05: duplicate `gnupg`,
`signal-cli`, `tailscale`, and `ngrok`, plus the unused `ngrok/ngrok` tap,
were removed after Nix activation and version checks. GPG's existing keyring
was retained and its agent restarted under Nix. Network accounts/state remain
app-owned; installing these CLIs does not enable services.

Global `postgresql@17` and `redis` binaries were also removed. Neither Homebrew
service was running; their data/configuration was retained, including Redis's
checksum-verified `dump.rdb`. Future databases belong in project containers
with explicit persistent volumes and backup/export instructions, not in the
global laptop installer.

The old `/Applications` copies of OrbStack, Zoom, and CrossOver were moved to
`~/Private/System Migration/Application Archives.noindex/2026-10-05/` after
activation and verification. Their sole installed owner is now
`~/Applications/Home Manager Apps/`. OrbStack's six previously running
containers were restarted; VM data, privileged helper, CrossOver bottles,
licenses, and Zoom account data were not removed. The archive is recoverable,
local-only rollback state, not freed disk space or an off-device backup.

Run `make app-audit` to read installed bundle IDs, versions, and paths without
launching or changing apps. `make app-audit ARGS=--check` fails on multiple real
bundles with the same ID; symlink aliases and repeated roots are deduplicated.
It checks the main app folders and one level of vendor subfolders, not app
internals or every disk. A duplicate is a review finding, not permission to delete.

The writing profile's practical usage is in [Writing workflow](writing-workflow.md).

## Adoption and cleanup rule

Prefer a smooth free/open-source tool with open formats and a practical export
path. A proprietary app is acceptable when it materially improves the work;
independence is not a reason to create a fragile self-hosting obligation.

1. Start with the shared base and the selected desktop defaults.
2. Add a capability only on a machine that uses it.
3. Give active projects pinned environments; do not rebuild every old project.
4. Audit installed apps against actual use. Identify exact targets, preserve
   app-owned data, and get approval before removal.
5. Keep one sync transport per dataset and an independent, tested backup.
