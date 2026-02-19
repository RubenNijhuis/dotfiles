# Runbook: Repository Migration

## 1. Validate repos

```bash
make validate-repos
```

## 2. Optional local rules

```bash
cp templates/local/migration-rules.txt.example local/migration-rules.txt
```

Edit `local/migration-rules.txt` if you want deterministic folder mapping.

## 3. Preview

```bash
make migrate-dev-dryrun
```

## 4. Execute

```bash
make migrate-dev
```

## 5. Handle remaining edge cases interactively

```bash
make complete-migration
```

## 6. Verify

```bash
make doctor
find "$HOME/Developer" -name '.git' -type d | wc -l
```
