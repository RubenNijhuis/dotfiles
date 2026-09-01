# Application catalog

This is the decision record for software that belongs in the personal setup.
It deliberately separates a portable everyday experience from optional
capabilities and from machine-specific software. A declaration is an
installation preference, not permission to remove an application that is
already on a machine.

## Free and open-source policy

Choose software in this order:

1. Free/open-source software with an open, local data format.
2. Free/open-source client backed by an interoperable service (IMAP, CalDAV,
   WebDAV, Matrix, or a standard Git repository).
3. A proprietary service only where its practical benefit is clear and there
   is an export path.

This does not mean self-hosting everything immediately. A rushed personal
server is more fragile than a well-backed-up local file. Start by choosing
open formats and applications that can move; self-host only a service that is
valuable enough to maintain.

## Everyday core: one experience on every personal device

| Need | Standard to adopt | Why it travels | Configuration boundary |
| --- | --- | --- | --- |
| Browser | **Zen** on macOS, Linux, and Windows | Free/open-source Firefox-based browser already in daily use; retain one small extension set and its supported sync rather than copying browser profiles. | Keep Zen as the desktop standard; use a separate mobile browser where Zen is unavailable. |
| Desktop email | **Thunderbird** | A consistent mail, calendar, and contacts client on Windows, macOS, and Linux. | Add accounts with IMAP/OAuth on each device; do not copy profile databases or credentials. |
| Calendar | **Google Calendar as the temporary operational source; Apple Calendar on Apple devices and Thunderbird elsewhere** | Google supplies the currently available ChatGPT calendar connection; Apple Calendar supplies native Apple notifications, while Thunderbird and the web cover Windows and Linux. | Keep calendars in separate named collections, use standard invitations and `.ics` exports, and review an optional CalDAV/Nextcloud pilot before treating Google as permanent. |
| Passwords | **KeePassXC + a KDBX vault** | Free/open-source desktop client for Windows, macOS, and Linux; the encrypted vault is a portable file rather than an account silo. | Store the KDBX vault in an encrypted, backed-up sync location; use a compatible mobile client, never this repository. |
| Notes | Markdown files now; evaluate **Logseq** before migrating | Existing Obsidian content remains portable Markdown, while Logseq is an open-source, local-first alternative. | Keep the present vault intact; trial a new Logseq graph before any migration. |
| Terminal | cmux on this Mac; Ghostty on macOS/Linux or Windows Terminal on Windows when chosen | The shell, prompt, Git, and editor remain the portable experience; terminal emulators are host-specific. | Nix owns the shared shell configuration. |
| Editor | **VS Code** now; evaluate VSCodium later | VS Code is the smooth current GUI editor path; Neovim remains the portable terminal editor. VSCodium is worthwhile only if the required extension/debugging workflow remains intact. | Keep extensions small and project-relevant; do not copy editor profile databases between devices. |
| Fonts | **Open Sans + Fira Code Nerd Font** | One readable proportional face for mail and documents, plus one coding face with terminal glyphs. | Nix declares both; applications may choose them but no application database is synchronized. |

Zen is already the browser standard. Thunderbird is the next adoption: add
mail, calendar, and contacts through IMAP/OAuth, CalDAV, and CardDAV on each
device. Do not copy browser or mail profile databases through Nix or file
synchronization.

## Calendar standard

Calendar is a service decision, not a Nix package. Nix can install the
clients, but it must never contain account credentials or event data.

For the smoothest path today, keep **one operational calendar account** in
Google Calendar: it works in Apple Calendar, Thunderbird, browsers, Windows,
Linux, and the current ChatGPT calendar app. Apple Calendar remains the
default interface on the Mac, iPhone, iPad, and Apple Watch, so its native
alerts continue to work. Thunderbird becomes the consistent desktop client on
every computer; its own alerts are enabled only on devices where they are
useful, to avoid duplicate notifications.

Use these calendars, rather than one undifferentiated list:

| Calendar | Purpose | Sharing / notification rule |
| --- | --- | --- |
| Personal | Appointments, travel, and life admin | Private; alerts on phone and primary Mac. |
| Work & projects | Time-blocking and project commitments | Share only when a collaboration requires it. |
| Family & shared | Events other people need to see | Explicit share permissions; never use a public link for private events. |
| Subscriptions | Holidays, sports, public schedules | Read-only `.ics` subscriptions; no alerts by default. |

This is deliberately a **reversible bridge**, not a claim that Google is the
long-term owner of the calendar. A future Nextcloud/CalDAV account can replace
the operational account without changing Apple Calendar or Thunderbird. First
prove it with one non-critical calendar, HTTPS, an app password, a tested
export, and a backup. Do not dual-write the same events across services; use
one source of truth and read-only subscriptions for everything else.

An AI connection is an explicit, separately reviewed permission. It may read
or act on calendar data according to the permissions granted to that app. Do
not connect private, shared, or sensitive calendars merely for convenience;
start with Personal and Work & projects only after reviewing the scopes.

## Current adoption map

This is the small daily setup to converge on. “Pilot” means test alongside the
current tool; it is not a removal instruction.

| Profile | Adopted now | Next adoption | Kept available, not baseline |
| --- | --- | --- | --- |
| Shared core | Zen, Thunderbird, cmux, Nix shell, Git, Neovim, Obsidian/Markdown, Signal | KeePassXC test vault | Chrome only as a compatibility fallback; Raycast stays macOS-only |
| Development | Node/pnpm, VS Code where its debugging/extensions help, OrbStack on Mac | project-local devShells as projects reopen | databases, cloud SDKs, language runtimes, IDEs, and API clients |
| Writing | Zen, Markdown/Obsidian | Thunderbird mail/calendar/contacts | Logseq trial only if it materially improves the current notes workflow |
| Design | Affinity/Figma when a project needs them; Krita and RawTherapee as opt-in open tools | Inkscape/Blender trial when an open tool fits the task | Processing and specialist tools |
| Audio & video | DaVinci/Blackmagic where actively used; HandBrake as the GUI converter | VLC/Audacity as portable complements | Spotify, Sonos, Rekordbox, and other service-specific tools |
| Gaming | none on the Mac baseline | Linux desktop gaming profile | Steam/Proton, Heroic, Prism, Discord, and game libraries |

The practical independence rule is simple: use the smoothest tool that works,
but retain open file formats, an export path, and an independent backup for
anything important. No profile should copy opaque application databases,
credentials, browser profiles, or mail stores between devices.

## Open-source creative and leisure defaults

| Discipline | First choice | Proprietary software kept optional |
| --- | --- | --- |
| Design / illustration | Krita, Inkscape, GIMP, Blender | Figma, Affinity |
| Audio | Audacity, Ardour, VLC | Spotify, Sonos, Rekordbox |
| Video | Kdenlive, FFmpeg, VLC | none by default |
| Communication | Signal; Element with Matrix where federation matters | Discord, WhatsApp, Slack |
| Gaming | Linux + Steam/Proton as a compatibility layer; Heroic and Prism Launcher are open-source launchers | Epic Games launcher; games and some stores remain proprietary |

Gaming is the deliberate exception: it belongs on the Linux desktop and will
often use proprietary game stores or anti-cheat systems. The host stays free
to remain lean on the MacBook.

## Capability modules

| Capability | Portable command-line layer | Native apps, installed only where needed | Intended hosts |
| --- | --- | --- | --- |
| Development | Nix `development` | VS Code, Podman/Docker only when needed, DBeaver | MacBook, Linux desktop, WSL |
| Writing | Nix `writing` | Zen, Thunderbird, Markdown/Logseq | Every personal computer |
| Design | Nix `design`: asset tools; Krita and RawTherapee are Nix-managed on Linux and a documented Apple-Silicon Homebrew exception | Inkscape, GIMP, Blender | Machines used for visual work |
| Audio & video | Nix `media`: portable media tools; HandBrake is a temporary documented macOS Homebrew exception while its pinned Nix package is broken | DaVinci Resolve, Kdenlive, Audacity, VLC | MacBook or desktop that actually handles media |
| Gaming | Nix `gaming` for helper tools | Steam, Heroic, Prism Launcher | Linux desktop only |
| Hardware / local services | Project-specific tools | Arduino IDE, Jellyfin server, ngrok, LM Studio | Only the machine attached to that work |

The Nix modules are deliberately small and portable. Install a GUI app through
Nix whenever its pinned package supports the host; keep only documented macOS
exceptions in the platform catalog when upstream support is missing or broken.

## Current application inventory: what to stop installing by default

The existing `Brewfile.apps` is retained as an inventory during the
transition, but it should no longer be treated as a laptop baseline. It mixes
three browsers, development tools, personal communication, media work,
gaming, local services, and Java versions in one automatic install.

| Group | Keep as an opt-in capability, not core |
| --- | --- |
| Alternative browsers | Google Chrome, Firefox, Helium — Zen is the chosen desktop standard; keep any fallback explicit and temporary. |
| Work-style communication | Slack, Linear, MeetingBar — no longer core now that the Celebratix work context is gone. |
| Specialist development | DBeaver, gcloud CLI, Rider, Docker/OrbStack, Yaak, Arduino IDE, JDK 11/17. |
| Creative / media | Affinity, Figma, Processing, IINA, Rekordbox, Sonos, Spotify. |
| Gaming / leisure | Steam, Epic Games, Prism Launcher, Discord. Keep these on the Linux desktop. |
| Local services / utilities | LM Studio, Ollama, Jellyfin, ngrok, Dropbox, Trackweight, CodexBar. Add only with a concrete use. |

## Installation rule

1. A fresh machine gets the shared Nix base and the everyday core you chose.
2. Add a capability module only when that machine serves that discipline.
3. Project runtimes belong in a project `devShell`, not in the global setup.
4. Keep a 30-day observation period before uninstalling anything; the current
   cleanup changes package declarations only and do not remove installed apps.

This is the common durable pattern in modular Nix setups: a small host base,
composable user capabilities, and platform-specific GUI application lists.
