# Documentation

Start with the document for the task at hand. Installation and personal-data
recovery have one checklist; ownership decisions and historical evidence have
separate reference documents.

## Start here

- [New Mac Recovery](runbooks/new-mac-recovery.md) — the installation and recovery checklist
- [Incident Recovery](runbooks/incident-recovery.md) — resume a failed installer or recover configuration
- [Nix Ownership Matrix](nix-ownership-matrix.md) — current owners, private state and adoption rules
- [Application Catalog](application-catalog.md) — application restore paths and manual handoffs
- [Storage Maintenance](storage-maintenance.md) — exact approved cleanup outcomes and dated evidence

The storage record, macOS audit dates and package-manager audit describe past
checks. They are not proof of current sync, remote code coverage or available
rollback generations. Independent backup and OS update/restart decisions remain
deferred; see the recovery checklist before any future erase.

## Architecture & Design

- [Architecture](architecture.md) — repo structure, scope, and design decisions
- [Nix environment](nix-transition.md) — capabilities, project runtimes, Linux/WSL activation and dated migration evidence
- [Machine Profiles](machine-profiles.md) — how profile selection works and how to use it
- [Personal File System](personal-file-system.md) — durable file placement, sync, and backup policy
- [File-sync options](file-sync-options.md) — iCloud, Nextcloud, Syncthing, and cross-platform tradeoffs
- [macOS Settings Migration](macos-settings-migration.md) — declarative macOS settings coverage
- [ChezMoi retirement](chezmoi-migration.md) — former-owner retirement and archive limitations
- [Shell Performance](shell-performance.md) — startup time optimisation

## Tool Configuration

- [cmux](cmux.md) — Nix-owned terminal preferences, shortcuts, and adoption
- [EditorConfig](editorconfig.md) — consistent coding styles across editors
- [Git Hooks](git-hooks.md) — pre-commit and other repo hooks
- [VS Code](vscode.md) — editor settings and extensions
- [Launchd automation](../launchd/README.md) — templates and management contract

## Operations & Runbooks

- [Runbook: Backups](runbooks/backup.md)
- [Writing workflow](writing-workflow.md)
- [Personal application policy](personal-application-policy.md)
