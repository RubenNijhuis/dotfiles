# Git Hooks

Install with `make hooks` (or `bash git-hooks/install-hooks.sh`).

See `docs/git-hooks.md` for what each hook checks.

## Testing

```bash
bash .git/hooks/pre-commit
bash .git/hooks/pre-push
```

## Bypassing (emergencies only)

```bash
git commit --no-verify
git push --no-verify
```
