# Runbook: Repository Migration

## 1. Validate repos

```bash
bash scripts/migration/validate-repos.sh
```

## 2. Optional local rules

```bash
cp templates/local/migration-rules.txt.example local/migration-rules.txt
```

Edit `local/migration-rules.txt` if you want deterministic folder mapping.

## 3. Preview

```bash
bash scripts/migration/migrate-developer-structure.sh --dry-run
```

## 4. Execute

```bash
bash scripts/migration/migrate-developer-structure.sh
```

## 5. Handle remaining edge cases interactively

```bash
bash scripts/migration/migrate-developer-structure.sh --complete
```

## 6. Verify

```bash
make doctor
find "${DOTFILES_DEVELOPER_ROOT:-$HOME/Developer}" -name '.git' -type d | wc -l
```
