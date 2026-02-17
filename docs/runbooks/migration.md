# Runbook: Developer Directory Migration

## Commands

```bash
make validate-repos
make migrate-dev-dryrun
make migrate-dev
make complete-migration
```

## Required Structure

```text
~/Developer/
├── personal/{projects,experiments,learning}
├── work/{projects,clients}
└── archive/
```

Reference: `docs/developer-migration.md`.
