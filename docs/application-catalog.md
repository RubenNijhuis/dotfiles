# Application catalog

Nix is the first-choice package owner. Use Homebrew only for a documented
macOS exception; keep account data and application databases outside Git.
This is an installation policy, never authorization to uninstall an app.

## Everyday defaults

| Task | Preferred app | Configuration boundary |
| --- | --- | --- |
| Browser | Zen Twilight on this Mac; Zen on other desktops | Nix supplies the desktop browser. Sessions, extensions, passwords, and supported browser sync remain app-owned. |
| Email | Thunderbird | IMAP/OAuth accounts are set up per device. Never synchronize its profile database. Apple Mail may remain the iPhone client. |
| Calendar | Apple Calendar on Apple devices; Thunderbird elsewhere | Keep one source per calendar. This Mac currently has iCloud and local calendars; Google is not a mandatory provider. Configure accounts and alerts separately from Nix. |
| Passwords | Apple Passwords / iCloud Keychain | The current single source of truth. Credentials, passkeys, recovery codes, and exports never belong in Nix or this repository. |
| Notes | Obsidian, plain Markdown under `~/Files` | On this Mac, `~/Files` points to the Files vault in Obsidian's iCloud container. Preserve the same taxonomy; iPhone two-way sync still needs its device test. Windows/Linux sync is a separate decision, not an automatic WebDAV migration. |
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

OneMenu is a manual Mac-only exception: no suitable package was found in the
pinned Nix set or Homebrew during its audit. Keep it; record a new package
owner only after verifying a replacement. Reassess exceptions when updating
the Nix pin, rather than importing the entire installed Homebrew inventory.

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
