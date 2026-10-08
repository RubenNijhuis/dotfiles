# Documentation

Index for the dotfiles documentation.

## Architecture & Design

- [Architecture](architecture.md) — repo structure, scope, and design decisions
- [Nix Transition](nix-transition.md) — current cross-platform installation and ownership model
- [Nix Ownership Matrix](nix-ownership-matrix.md) — source of truth for what Nix manages
- [Machine Profiles](machine-profiles.md) — how profile selection works and how to use it
- [Application Catalog](application-catalog.md) — portable daily tools and optional capabilities
- [Personal File System](personal-file-system.md) — durable file placement, sync, and backup policy
- [File-sync options](file-sync-options.md) — iCloud, Nextcloud, Syncthing, and cross-platform tradeoffs
- [macOS Settings Migration](macos-settings-migration.md) — declarative macOS settings coverage
- [Storage Maintenance](storage-maintenance.md) — read-only sizes and approval-bounded cleanup
- [Shell Performance](shell-performance.md) — startup time optimisation

## Tool Configuration

- [cmux](cmux.md) — Nix-owned terminal preferences, shortcuts, and adoption
- [EditorConfig](editorconfig.md) — consistent coding styles across editors
- [Git Hooks](git-hooks.md) — pre-commit and other repo hooks
- [VS Code](vscode.md) — editor settings and extensions
- [Launchd automation](../launchd/README.md) — templates and management contract

## Operations & Runbooks

- [Runbook: Backups](runbooks/backup.md)
- [Runbook: Incident Recovery](runbooks/incident-recovery.md)
- [Runbook: New Mac Recovery](runbooks/new-mac-recovery.md)
