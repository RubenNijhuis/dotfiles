# Nix transition

The Nix configuration lives at the repository root so macOS, Linux, and WSL
share the same pinned inputs and Home Manager package set.

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

Language runtimes do not have global capability modules: an active repository
gets its own pinned `devShell`. The shared core is Git, search/preview, and
terminal/navigation; `developer` is the small portable maintenance layer.
[`templates/nix-project/`](../templates/nix-project/) is the minimal starting
point for a Node project that needs one.
The MacBook and Linux desktop also import `writing`. The Windows desktop's WSL
peer imports only the command-line base and developer layers; its browser,
mail, notes, and gaming applications remain native Windows applications. Add
`design` or `media` only when that machine genuinely serves the discipline.
The Linux desktop adds the separate `gaming` capability. The Mac keeps its
occasional gaming launcher as a narrow, opt-in Homebrew exception.

| Device role | Nix target | Deliberate difference |
| --- | --- | --- |
| Primary Mac | `Rubens-MacBook-Pro` | desktop core, developer, browser, writing, and macOS apps |
| Windows desktop / WSL | `rubennijhuis-windows-wsl` | command-line core and developer only; native Windows GUI and games stay outside WSL |
| Linux desktop | `rubennijhuis-linux-desktop` | desktop core, developer, browser, writing, and Linux-only gaming |

The corresponding native application decisions live in the
[application catalog](application-catalog.md). It defines a portable
everyday core—rather than trying to make every platform install the same
large GUI list.

The reasoning behind this structure and the staged migration plan are in
[Nix setup research: durable patterns to adopt](nix-research-takeaways.md).

## Ownership during the transition

| Concern | Current owner | Planned owner |
| --- | --- | --- |
| Portable desktop apps | Home Manager | Home Manager where the pinned package supports the host |
| Specialist macOS apps | documented Homebrew/manual exception | revisit after each Nixpkgs update |
| Existing dotfiles | Nix or ChezMoi by path | Home Manager, one program at a time |
| Cross-platform CLI packages | Home Manager | Home Manager |
| Per-project runtimes | temporary local mise state where an active project needs it | project `devShell`s; use Nix-provided tools rather than a global mutable runtime manager on a new machine |
| macOS defaults and launch agents | nix-darwin / launchd plists | nix-darwin / Home Manager where supported |
| Secrets | Keychain and machine-local config | Keychain and machine-local config |

Never put a secret in `flake.nix`, `flake.lock`, or a Nix module: Nix store
paths are broadly readable on the machine.

## First installation

1. Install a Nix implementation for macOS. The nix-darwin project recommends
   the Lix installer because it provides a supported uninstall path.
2. From this repository, inspect the locked evaluation and build:

   ```bash
   make nix-check
   make nix-build
   ```

   Before changing shared modules that affect Linux or WSL too, use the
   cross-platform check:

   ```bash
   make nix-check-all
   ```

3. Apply the macOS configuration:

   ```bash
   make nix-switch
   ```

`make nix-switch` bootstraps nix-darwin through Lix if `darwin-rebuild` is not
yet installed; later switches use the installed command. The Mac configuration
includes its shared CLI and supported desktop application profiles. It does not
uninstall Homebrew packages automatically. It takes over only files explicitly
declared by the active Home Manager modules; the ownership matrix records each
handoff and the small list of macOS package exceptions.

If this Mac already has `/etc/pam.d/sudo_local` from a prior Touch ID setup,
preserve it once before the first switch so Nix can take over that exact file:

```bash
sudo -H mv /etc/pam.d/sudo_local /etc/pam.d/sudo_local.before-nix-darwin
make nix-switch
```

The renamed file is a recoverable pre-Nix backup; nix-darwin then writes the
same enabled Touch ID rule from `nix/darwin/defaults.nix`.

## Linux and Windows

Use the same flake with standalone Home Manager on Linux or inside WSL:

```bash
make nix-home-switch NIX_HOME_HOST=rubennijhuis-windows-wsl
```

Use `NIX_HOME_HOST=rubennijhuis-linux-desktop` for an x86_64 Linux desktop
with gaming, or `NIX_HOME_HOST=rubennijhuis-linux-aarch64` for ARM Linux.
Native Windows remains outside the Nix support boundary; WSL is the supported
Windows path.

## Migration rule

For each program, build the Home Manager replacement, activate it, then stop
ChezMoi from managing that target and verify the resulting file and command
resolution. Raw source files may remain in the repository when a Nix module
consumes them. Do not allow both managers to write the same path.
