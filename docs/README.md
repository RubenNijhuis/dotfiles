# Documentation

Index for the dotfiles documentation.

## Architecture & Design

- [Architecture](architecture.md) — repo structure, scope, and design decisions
- [Nix Transition](nix-transition.md) — current cross-platform installation and ownership model
- [Nix Ownership Matrix](nix-ownership-matrix.md) — source of truth for what Nix manages
- [Machine Profiles](machine-profiles.md) — how profile selection works and how to use it
- [Application Catalog](application-catalog.md) — portable daily tools and optional capabilities
- [Personal File System](personal-file-system.md) — durable file placement, sync, and backup policy
- [Runbook: Cross-device sync pilot](runbooks/sync-pilot.md) — a small, reversible Syncthing and Restic rollout
- [macOS Settings Migration](macos-settings-migration.md) — declarative macOS settings coverage
- [Shell Performance](shell-performance.md) — startup time optimisation

## Tool Configuration

- [EditorConfig](editorconfig.md) — consistent coding styles across editors
- [Git Hooks](git-hooks.md) — pre-commit and other repo hooks
- [VS Code](vscode.md) — editor settings and extensions
- [LaunchD Examples](launchd-examples.md) — reusable LaunchD automation templates

## Operations & Runbooks

- [Runbook: Backups](runbooks/backup.md)
- [Runbook: Incident Recovery](runbooks/incident-recovery.md)

## Reference

- [CLI Reference](reference/cli.md) — generated command docs (`bash ops/generate-cli-reference.sh`)
- [Reference Index](reference/README.md)
