# Developer Repository Migration

This repo supports two migration scenarios:

- Fresh machine: no legacy source exists, migration exits cleanly.
- Existing machine: move repos from a legacy source tree into a structured target tree.

## Defaults

- Source: `$DOTFILES_DEVELOPER_ROOT/repositories`
- Target: `$DOTFILES_DEVELOPER_ROOT`
- Default destination: `personal/projects`
- Optional rules file: `local/migration-rules.txt`

## Command Modes

```bash
# Preview (no file changes)
make migrate-dev-dryrun

# Auto mode (rules + heuristics)
make migrate-dev

# Interactive mode (choose destination per repo)
make complete-migration
```

## Direct Script Usage

```bash
scripts/migration/migrate-developer-structure.sh \
  --source "$DOTFILES_DEVELOPER_ROOT/repositories" \
  --target "$DOTFILES_DEVELOPER_ROOT" \
  --rules "local/migration-rules.txt" \
  --default-destination "personal/projects"
```

Useful flags:

- `--dry-run`
- `--complete`
- `--non-interactive`
- `--no-color`

## Rules File

`local/migration-rules.txt` format:

```text
pattern|destination-subpath
```

Pattern matches `<relative-source-path>/<repo-name>` using shell globs.

Example:

```text
Work/*|work/projects
Clients/*|work/clients
Experiments/*|personal/experiments
Learning/*|personal/learning
Legacy/*|archive
```

## Safety Behavior

- Creates a backup of source before moving (non-dry-run).
- Skips targets that already exist.
- Prints summary of moved/skipped/failed repositories.

## Validation

```bash
make validate-repos
make doctor
```
