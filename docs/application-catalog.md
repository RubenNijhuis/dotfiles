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
| Development | Nix maintenance, Node 24/pnpm, formatters, GitHub CLI, Bash/Lua language servers | VS Code; OrbStack on this Mac. Pin other runtimes and package-manager requirements in each active project. |
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

Jujutsu, Hyperfine and the unconfigured `nil`/`nixd` language servers are opt-in
through `nix develop .#developer-extras` in this repository. Gum stays in the
baseline because the existing confirmation prompts use it. Biome/Prettier,
GNU Parallel and the shell tools remain because editor and maintenance commands
actually call them; the two formatters cover different file types.

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
On 2026-10-13 a refreshed RawTherapee Nix build still failed on Linux-only `libselinux`
dependency despite permissive package metadata; HandBrake is marked broken on
Darwin and Krita is Linux-only. Keep those exceptions until builds actually work.

Update gate on 2026-10-15: retain Nixpkgs `8edc0c7`. The proposed `ca16594`
pin failed to build Sesh's Go Mockery dependency (Go export-data incompatibility).
Separately, both retained Obsidian 1.13.7 and proposed 1.14.4 have the same
ad-hoc bundle-signature limitation under native strict verification; this is
not a new update regression. Do not disable tests or signature checks to force
the package-set update through.

OneMenu is a manual Mac-only exception: no suitable package was found in the
pinned Nix set or Homebrew during its audit. Keep it; record a new package
owner only after verifying a replacement. Reassess exceptions when updating
the Nix pin, rather than importing the entire installed Homebrew inventory.

## Native restore boundaries

Read-only bundle inventory refreshed on 2026-10-13, excluding Apple system apps
and games inside launcher libraries. This is a recovery/ownership list, not
an uninstall request; installation and age do not establish actual use:

| Area | Existing manually managed applications |
| --- | --- |
| Communication | WhatsApp, Slack, Discord; the app named ChatGPT is retained as-is pending identity review |
| Creative work | DaVinci Resolve and Blackmagic utilities, Affinity, Figma, rekordbox and Pioneer updater, Processing |
| Leisure | Spotify, Steam; retain existing games and saves |
| Platform tooling | Xcode, OneMenu |
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
| WhatsApp, Slack | Official app installer/updater for now: installed versions 26.41.14 and 4.51.191 are newer than the refreshed pin's 2.26.31.27 and 4.51.180 (rechecked 2026-10-13). Do not downgrade. |
| Discord | The refreshed Nix 0.0.414 matches the installed version and builds, but strict bundle verification fails on added module resources; the native app passes. Retain the vendor installation, without re-signing or bypassing macOS protections just to migrate it. |
| App named ChatGPT | Its bundle ID is `com.openai.codex`. Preserve this actual app and use its supported updater until a matching replacement is verified; filename alone does not establish identity. |
| Spotify | Official writable installation (currently 1.3.3.264); Spicetify must not patch a Nix-store app. The pin is also older (1.2.98.301). |
| Steam | Native Mac Steam installer; the pinned Steam derivation is not a supported Darwin package. Game saves and Cloud status are separate. |
| Resolve / Blackmagic tools | Vendor-owned Resolve 20.2.3; [Blackmagic support installers](https://www.blackmagicdesign.com/support/). The pinned Resolve is Linux-only. Restore exported projects and source media separately. Installed companions include Proxy Generator Lite 20.2.3, Remote Monitor 20.2, RAW Player/Speed Test 5.1, panel utilities and the uninstaller; these are installer components, not extra profile requirements. |
| Affinity / Figma | Vendor-owned Affinity 3.0.1 and Figma 125.9.10. No matching native Mac package in the pin; `figma-linux` is not the Mac client. [Figma downloads](https://www.figma.com/downloads/). Figma's local-font helper is app-managed, not a separate installer requirement. |
| rekordbox / Pioneer tools | Vendor-owned rekordbox 6.7.7.0003 and Pioneer Firmware Downloader 1.0.1.0; [rekordbox installer](https://rekordbox.com/en/download/) and hardware-specific vendor updates. Keep libraries/licenses outside Nix; do not silently replace version 6 with a newer major version. Hardware need is not established by bundle metadata. |
| Krita / RawTherapee / HandBrake | Selected Homebrew exceptions: Krita 5.3.4 (installer revision 5.3.4.1), RawTherapee 5.13 and HandBrake 1.11.2. They supply illustration, RAW-photo development and graphical conversion respectively; retain the existing verified exceptions above. |
| Processing | Vendor-owned 4.3, retained with its Cropper sketch under Developer. Its bundled Java is separate from system/gaming Java. The pinned Processing is Linux-only; source sketches are not disposable app files. |
| Python.org 3.11 / Oracle Java 8 plugin | Retired to recoverable Trash after exact approval; no baseline restore requirement. Python 3.11's global Compose-format/ruamel.yaml tools retired with it. Prism's JDKs and Apple system tools remain. |
| Xcode / OneMenu | Xcode via Apple's supported installer/App Store; [OneMenu vendor installer](https://coffeebreak.software/one-menu/). No verified Nix equivalent for OneMenu. |
| Chrome | Retained for compatibility, not the default. Its installed build is newer than the pin; recheck before migrating. Never import browser profiles into Nix. |

This inventory is not a claim that each app is needed or that it is fully
recoverable. Licenses, sign-ins, media libraries, and app-local work need their
own supported recovery paths. Re-evaluate temporary version exceptions when
updating the Nix pin rather than adding bespoke overrides for every GUI app.

### Settings and work recovery

Recovery review on 2026-10-14 read bundle metadata and selected non-secret
preferences only. Nix already restores Raycast's preferred-app Script Commands;
no supported portable configuration was established for the remaining native
settings below. Keep those settings editable in their apps rather than linking
whole preference folders or databases into Git.

| App | What to restore after installation |
| --- | --- |
| OneMenu 2.8.0 | In the app, enable automatic updates and launch at login; disable its window manager; retain spacing `0.5`. These are observed reference values, not a stable configuration API. Login-item registration and Accessibility consent must be recreated on each Mac. No supported settings export was found on the [vendor page](https://coffeebreak.software/one-menu/). |
| Raycast 2.6.3.0 | Register `~/.config/raycast/script-commands/` in Settings → Extensions → Script Commands; restore the launcher hotkey and appearance through Settings. The observed global hotkey is Command-Space and appearance follows macOS. [Script Commands](https://manual.raycast.com/script-commands) are the supported plain-file boundary. For other preferences, the [native export](https://manual.raycast.com/import-export) is encrypted but can include clipboard history, AI chats and private extension state; export only after reviewing the exact scope. Import only the required categories, then verify the directory and hotkey. |
| Krita | If custom brushes, palettes or workspaces are actually used, create/import selected `.bundle` resources through Settings → Manage Resource Libraries. Export custom keyboard shortcuts separately. Preserve editable `.kra` source files; the resource database is not the restore artifact. [Resources](https://docs.krita.org/en/reference_manual/resource_management.html), [shortcut export](https://docs.krita.org/en/reference_manual/preferences/shortcut_settings.html). |
| RawTherapee | Preserve original photos with their `.pp3` editing sidecars and any deliberately saved processing profiles. Re-enter UI/theme/monitor preferences on the destination machine; a display-specific profile is not a portable default. [Sidecars and profiles](https://rawpedia.rawtherapee.com/The_Image_Editor_Tab), [preferences](https://rawpedia.rawtherapee.com/Preferences). |
| HandBrake | Export/import only custom presets through the preset pane; select the preferred default after import. Presets restore conversion rules, not input media or completed output. No `UserPresets.json` was found at the documented Mac path during this review, so no personal preset is assumed. [Custom presets](https://handbrake.fr/docs/en/1.11.0/advanced/custom-presets.html). |
| Resolve | Use the installed version's native project export/archive and restore operations; retain original media and confirm the restored project has no offline assets. A project-only export is not proof that its media is included. Retain any deliberately exported projects and media; do not assume the retired migration folder is a backup or copy a live project-library database into Git. Use the matching manual from [Blackmagic support](https://www.blackmagicdesign.com/support/). |
| Affinity / Figma | Retain editable local source documents; restore app/account access separately. Affinity 3's whole-settings export was not verified, so do not apply older Affinity 2 restore instructions to it. Figma's [Save local copy](https://help.figma.com/hc/en-us/articles/8403626871063-Save-a-local-copy-of-files) preserves a file snapshot but omits comments and version history; reimport creates a new file. |
| rekordbox 6 | Use File → Library → Backup Library / Restore Library, with music included where needed. Preserve that music and keep its backup folder alongside the library backup. Restore version 6 deliberately; hardware settings and licences remain app-owned. [Version 6 manual](https://cdn.rekordbox.com/files/20230316171900/rekordbox6.7.0_manual_EN.pdf). |
| Steam | Sign in through Steam; verify Cloud support and completed synchronization for each retained game. The developer decides which saves/settings are covered; global Cloud being enabled does not establish recovery for every game. Preserve local saves until a restore is tested. [Steam Cloud](https://help.steampowered.com/en/faqs/view/68D2-35AB-09A9-7678). |
| Prism Launcher | Preserve each retained instance's worlds, mods, options and resource packs through an explicitly reviewed instance export; check its file selection includes saves. The [native ZIP exporter](https://github.com/PrismLauncher/PrismLauncher/blob/develop/launcher/ui/dialogs/ExportInstanceDialog.cpp) honors file exclusions. [ZIP import](https://prismlauncher.org/wiki/getting-started/command-line-interface/) does not restore account sign-in or a working Java path. Select a compatible runtime per instance after import; retain the Oracle 22 global / Zulu 17 Minecraft 1.20.1 distinction below. |
| CrossOver | Export the selected retained bottle with Bottle → Export to Archive, then restore its `.cxarchive` with Import Bottle Archive. Inspect external save locations separately; licence activation stays app-owned. [Supported bottle recovery](https://support.codeweavers.com/2-common-actions/2-archiving-and-restoring-a-bottle). |

These are prepared restore handoffs, not completed exports or tested restores.
Native app exports and cloud uploads need an exact scope and explicit approval.
The 2026-10-15 follow-up found no custom Krita, RawTherapee or HandBrake
resources at the inspected conventional paths, so no speculative preset export
is needed. Actual local saves exist for Factorio, Oxygen Not Included,
Civilization VI, Papers, Please and ISLANDERS; their completed Steam Cloud
synchronization was not verified. The two inspected Prism instances had no
world saves. Preserve live save locations and use a reviewed copy/export, not
Nix links or a blanket copy of a launcher's databases.
The user chose to keep game saves local on 2026-10-15; no recovery snapshot or
cloud upload was made.
For approved non-secret reusable presets, use `~/Files/30 Resources/<App>/`;
keep project exports with their specific project under `~/Files/10 Projects/`
or its existing archive. Private Raycast exports, licences and account material
belong under `~/Private/`, outside Git and cloud-sync folders. Games, saves,
creative libraries, Mave archives and paused project databases remain retained.
Independent backup remains a separate deferred decision.

Audacity is not installed in the inspected app roots or declared in this setup;
it is an optional standalone-audio editor, not an unfinished requirement.
Resolve already supplies the preferred video/audio workflow. The Nix design
and media modules remain opt-in and are not imported by the current Mac or
Linux desktop: do not install their supporting CLI stacks just because the
modules exist. Keep Affinity/Figma and hardware tools pending an actual-use
decision; no specialist-app removal was established by this metadata review.

Arc, Brave and Pale Moon were retired with approval, including their reviewed
profiles and remnants. Zen, Safari and Chrome remain installed. The old browser
archives were subsequently retired on 2026-10-13; do not rely on them for recovery.
See [Storage maintenance](storage-maintenance.md) for the exact cleanup history.

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

OrbStack, Zoom and CrossOver now have one installed owner:
`~/Applications/Home Manager Apps/`. Their old `/Applications` copies and migration
archives were retired; VM data, privileged helpers, CrossOver bottles, licenses
and account data were not removed. The 2026-10-13 app audit found no duplicate
bundle IDs in its inspected roots, and the Homebrew audit found no undeclared
top-level installs. Krita's Homebrew installer revision was updated to 5.3.4.1
(the app still reports 5.3.4), and the retained Kerberos dependency to 1.22.2_2.
Homebrew remains limited to documented exceptions and their dependencies.

Gaming-runtime check on 2026-10-14: Prism's global Java path uses the retained
Oracle JDK 22, while the Minecraft 1.20.1 instance explicitly uses Zulu 17.
Preserve both; `Brewfile.gaming` restores Zulu 17, not the Oracle JDK. Recreate
any other required game runtime deliberately through its supported installer
or Prism's Java management rather than copying absolute paths to another OS.
The old Java 8 browser plugin is not either of these gaming dependencies.

Repository maintenance already has pinned Python in `nix develop .#maintenance`.
Do not replace a retired Python.org installation with a new global mutable
Python environment. Application dependencies belong in project environments.

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
