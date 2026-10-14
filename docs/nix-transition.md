# Nix environment and migration evidence

The Nix configuration lives at the repository root so macOS, Linux, and WSL
share the same pinned inputs and Home Manager package set. For installation,
use the [new-Mac checklist](runbooks/new-mac-recovery.md); for current owners,
use the [ownership matrix](nix-ownership-matrix.md).

## Capability profiles

Profiles are composable modules, not one mutually exclusive machine role.
Every host starts with the small base in `nix/home/common.nix` and the shared
core in `nix/profiles/core.nix`, then imports only the capabilities it needs:

| Capability | Scope | Contents |
| --- | --- | --- |
| `developer` | macOS, Linux, WSL | Nix maintenance, Node LTS, pnpm, GitHub CLI, shared formatters, and the small tooling this repository runs |
| `writing` | macOS, Linux, WSL | Typst, Pandoc, Vale, LanguageTool |
| `design` | macOS, Linux, WSL | image and SVG optimization tools; native apps stay platform-specific |
| `media` | macOS, Linux, WSL | FFmpeg, SoX, yt-dlp |
| `gaming` | Linux desktop only | Heroic, MangoHud, Prism Launcher; host owns GPU/Steam setup |
| `leisure` | opt-in macOS/Linux; active on this Mac | Spicetify CLI and reusable TokyoNight theme; Spotify runtime state stays writable and local |
| `network-tools` | opt-in; selected only on this Mac | Signal CLI, Tailscale CLI, ngrok; no services or account state |

Language runtimes do not have global capability modules: an active repository
gets its own pinned `devShell`. The shared core is Git, search/preview, and
terminal/navigation; `developer` is the small portable maintenance layer.
[`templates/nix-project/`](../templates/nix-project/) is the minimal starting
point for a Node project that needs one, including its own lock file:

```bash
# Run inside the specific code project, not ~/Files or the home directory.
nix flake init -t ~/Developer/personal/dotfiles#node
nix develop
```

Review the project's engine/packageManager requirements first. The template
provides Node 24 and the pinned Nixpkgs pnpm, not an arbitrary exact pnpm version
requested by a particular repository. Commit both flake files to that project;
update its lock independently. It adds no automatic directory hooks or services.
Databases belong in that project's container configuration, with explicit
persistent volumes and a documented export/restore path. Do not sync a running
database volume through iCloud or add global PostgreSQL/Redis services to the
laptop baseline. Container images and development runtimes are pinned and
updated by each project, independently of this dotfiles lock.
Until an older project receives its
own flake on its own branch, this repository offers one narrow compatibility
shell without changing the Node 24 default:

```bash
nix develop .#node22
```

It supplies Node 22 and its matching Yarn 1.x; use it only for projects whose
declared engine range excludes Node 24.
The MacBook and Linux desktop also import `writing`. The Windows desktop's WSL
peer imports only the command-line base and developer layers; its browser,
mail, notes, and gaming applications remain native Windows applications. Add
`design` or `media` only when that machine genuinely serves the discipline.
The Linux desktop adds the separate `gaming` capability. The Mac keeps its
occasional gaming launcher as a narrow, opt-in Homebrew exception.

Optional benchmarking, Jujutsu and Nix language-server experiments use a
separate shell:

```bash
nix develop .#developer-extras
```

This shell supplies Hyperfine, Jujutsu, `nil` and `nixd` on supported hosts.
It does not configure editor integrations or install them globally.

| Device role | Nix target | Deliberate difference |
| --- | --- | --- |
| Primary Mac | `Rubens-MacBook-Pro` | desktop core, developer, browser, writing, and macOS apps |
| Windows desktop / WSL | `rubennijhuis-windows-wsl` | command-line core and developer only; native Windows GUI and games stay outside WSL |
| Linux desktop | `rubennijhuis-linux-desktop` | desktop core, developer, browser, writing, and Linux-only gaming |

The corresponding native application decisions live in the
[application catalog](application-catalog.md). It defines a portable
everyday core—rather than trying to make every platform install the same
large GUI list.

The reasoning behind this structure and the original staged migration plan are in
[Nix setup research: durable patterns to adopt](nix-research-takeaways.md).

## Linux and Windows

Use the same flake with standalone Home Manager on Linux or inside WSL:

```bash
make nix-home-switch NIX_HOME_HOST=rubennijhuis-windows-wsl
```

Use `NIX_HOME_HOST=rubennijhuis-linux-desktop` for an x86_64 Linux desktop
with gaming, or `NIX_HOME_HOST=rubennijhuis-linux-aarch64` for ARM Linux.
Native Windows remains outside the Nix support boundary; WSL is the supported
Windows path. A successful Mac build does not verify Linux runtime behaviour.

## JavaScript manager audit — 2026-10-13

The following is preserved migration evidence. Its installed versions and
local inventory describe that date; use the current lockfile, project manifests
and executable checks when making a new runtime decision.

pnpm is the default for new personal projects, not a forced replacement inside
third-party frameworks or shared repositories. Nix owns the global Node
24.21.0/pnpm 12.9.0 launchers after the input refresh; each project owns its exact
manager and lockfile. The website's pnpm 12.8.1 and ThreeJS's 12.3.4 pins remain
unchanged rather than following this machine's launcher version.
npm remains part of Node for compatibility. Prefer Nix for shared CLIs and
project devDependencies for JavaScript-specific tools, rather than mutable
global npm/pnpm/Yarn installs.

The same-day input refresh updated Home Manager, Nixpkgs and Zen. All declared
platforms evaluated, the fresh-profile Neovim check passed, and the Mac build
was activated as generation 58. Installed versions include Thunderbird 157.0.1,
Signal 8.29.0, Raycast 2.6.3.0 and Zoom 7.2.2; the refreshed Zen still reports
1.24t. The inspected app roots have no duplicate bundle IDs, Thunderbird's
profile registration is unchanged, and no macOS update/restart was performed.

| Project | Manager / decision |
| --- | --- |
| Personal website | Already pnpm 12.8.1; verified that selection and left its active workspace unchanged. Bun is its project-installed research runtime, not a competing installer. |
| ThreeJS journey | Kept with an explicit pnpm 12.3.4 pin. Frozen lock check passed; the application graph is unchanged, with pnpm's tool-lock document added. This folder has no Git repository; changes remain local. |
| PortfolioFinal; SimRacingCenter | Subsequently retired to recoverable Trash at Ruben's request. The nested SRC-API checkout and its five modified files were preserved; its GitHub remote was not deleted. |
| TypeScript Decorators / Exercises | Historical pnpm 6-format lock / dependency-free exercise manifest respectively; left unchanged, not modernized just for uniformity. |
| Portfolio22 | Explicitly kept at Ruben's request. Retained npm: existing manifest edits, legacy Gatsby 4/node-sass 7 and its authoritative npm lock require a separate runtime/dependency migration. |
| Roodjongeren; Mijnrood | Retained Yarn 1.22.22: shared CI/container workflows and existing edits are not laptop-wide package-manager migrations. |
| Symfexit theme | Retained npm: develop/tests/rebuild helpers use npm/npx and its separate Dream2Nix build consumes package-lock.json. |
| Website workflow prototypes; generated PureScript output | Historical comparison material / generated output; excluded from migration. Mave archives remain untouched. |

Normal pnpm uses `~/.local/share/pnpm/store/v11`. A restrictive agent sandbox
can fall back to `node_modules/.pnpm-store`; do not mistake that for the user's
global configuration. Do not cloud-sync package stores or dependency directories.
After exact approval, the old `~/Library/pnpm/global/5` (about 251 MiB) and its
six wrappers were moved to `~/.Trash/Legacy-pnpm-globals-2026-10-13/`, preserving
their filesystem identities. Current Nix tools, project dependencies, package
caches and the current pnpm store were untouched; Trash was not emptied.
The old Yarn global manifest names create-r3f-app. The older home Bun runtime
and a Homebrew npm library also remain. The old Bun 1.1.29 was removed from the shared shell PATH,
not deleted; the research app's pnpm-selected Bun 1.4.2 was verified. From the
website root use `pnpm --filter @rubennijhuis/research-api exec bun --version`
or its existing research scripts, not an unqualified root-level Bun command.
No npm/pnpm cache pruning was performed as part of that runtime-manager audit.
The subsequent exact approved cache cleanup supersedes that hold; its verified
outcomes are in [storage maintenance](storage-maintenance.md). Further removal
still requires exact approval.

## Existing configuration collisions

The installer provisions Lix/Nix and builds/applies the locked configuration.
`make nix-switch` uses the rebuild tool from this flake's locked nix-darwin
input without refreshing the lock. Activation takes over only declared paths;
it does not uninstall unrelated Homebrew packages.

An existing `/etc/pam.d/sudo_local` can conflict with the first Touch ID
activation. Inspect the exact file and agree a recoverable, non-overwriting
backup before handing it to `nix/darwin/defaults.nix`. Do not routinely rename
it on every install or restore a retired configuration owner. For other
collisions, follow the [ownership change rules](nix-ownership-matrix.md#changes-to-ownership).
