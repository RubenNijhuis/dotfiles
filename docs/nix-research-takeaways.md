# Nix architecture principles

This repository follows the smallest proven multi-host Nix shape: pinned
inputs, shared Home Manager modules, thin host definitions, and composable
capabilities. The current configuration and its live ownership are recorded in
[Nix transition](nix-transition.md) and the
[Nix ownership matrix](nix-ownership-matrix.md); this document deliberately
does not duplicate their status tables or migration steps.

## Decisions

| Principle | Decision |
| --- | --- |
| Reproducibility | Commit `flake.lock`; update it deliberately and test before switching. |
| Sharing | Put portable behaviour in `nix/home/` and select capabilities in `nix/profiles/`. |
| Hosts | Keep host files to platform, machine, and selected capabilities. |
| GUI applications | Use the native platform package source; do not force one GUI installer across macOS, Linux, and Windows. |
| Languages | Prefer per-project `devShell`s entered through `direnv` over global runtimes. |
| Secrets | Keep credentials, keys, and recovery material out of the Nix store and repository. |
| Complexity | Do not add flake-parts, custom loaders, overlays, or a framework until the current readable structure has a concrete limit. |
| Migration | Give each path exactly one active owner and preserve a recoverable backup before a handoff. |

## Operating routine

1. Make a small, capability-scoped change.
2. Run `make nix-check` and `make nix-build`.
3. Apply only the intended target with `make nix-switch` or the matching Home
   Manager command.
4. Verify the changed command or configuration and retain the prior generation
   for rollback.

## Sources

- [Nix flake reference](https://releases.nixos.org/nix/nix-2.25.5/manual/command-ref/new-cli/nix3-flake.html)
- [Home Manager + nix-darwin flake guide](https://nix-community.github.io/home-manager/nix-flakes/nix-darwin.html)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
