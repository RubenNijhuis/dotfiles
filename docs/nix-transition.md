# Nix transition

The Nix configuration lives at the repository root so macOS, Linux, and WSL
share the same pinned inputs and Home Manager package set.

## Capability profiles

Profiles are composable modules, not one mutually exclusive machine role.
Every host starts with the small base in `nix/home/common.nix` and the shared
core in `nix/profiles/core.nix`, then imports only the capabilities it needs:

| Capability | Scope | Contents |
| --- | --- | --- |
| `development` | macOS, Linux, WSL | direnv and Nix tooling only |
| `javascript` | macOS, Linux, WSL | Node LTS and pnpm; selected by all current hosts |
| `rust`, `python`, `go` | macOS, Linux, WSL | Opt-in language environments, selected only by an active project |
| `writing` | macOS, Linux, WSL | Typst, Pandoc, Vale, LanguageTool |
| `design` | macOS, Linux, WSL | image and SVG optimization tools; native apps stay platform-specific |
| `media` | macOS, Linux, WSL | FFmpeg, SoX, yt-dlp |
| `gaming` | Linux desktop only | Heroic, MangoHud, Prism Launcher; host owns GPU/Steam setup |

The shared core is Git, search/preview, terminal/navigation, development, and
JavaScript. The MacBook is the primary device and imports that core. The
Windows desktop's WSL peer imports the same core; add `writing`, `design`, or
`media` only when that capability is genuinely needed there. The Linux desktop
adds the separate `gaming` capability, with no gaming software on the Mac or
inside WSL.

| Device role | Nix target | Deliberate difference |
| --- | --- | --- |
| Primary Mac | `Rubens-MacBook-Pro` | stable core; optional discipline profiles only when used |
| Windows desktop / WSL | `rubennijhuis-windows-wsl` | same core; Windows-native GUI and games remain outside WSL |
| Linux desktop | `rubennijhuis-linux-desktop` | core plus Linux-only gaming |

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
| Per-project runtimes | temporary local mise / rustup state | project `devShell`s; use Nix-provided `uv` or language tools, not a global runtime manager, on a new machine |
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
