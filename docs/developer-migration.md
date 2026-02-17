# Developer Directory Migration

Guide for migrating from a flat `~/Developer/repositories/` layout to the structured layout used by these dotfiles.

## Target Layout

```text
~/Developer/
├── personal/
│   ├── projects/
│   ├── experiments/
│   └── learning/
├── work/
│   └── clients/
└── archive/
```

## What the Migration Does

- Reorganizes repositories into the target structure.
- Preserves git history/remotes (repos are moved, not recreated).
- Creates a backup before migration.
- Supports dry-run preview.

## Preconditions

Before migration, ensure repositories are clean enough to move safely.

```bash
make validate-repos
```

If issues are reported, resolve them first:

- commit/stash uncommitted work
- push important local commits
- remove stale lock files if any

## Recommended Sequence

```bash
# 1) update dotfiles and shell setup
cd ~/dotfiles
git pull
make stow

# 2) validate repository state
make validate-repos

# 3) preview changes
make migrate-dev-dryrun

# 4) execute migration
make migrate-dev

# 5) complete cleanup/finalization
make complete-migration  # runs migrate-developer-structure.sh --complete
```

## Post-Migration Verification

```bash
# check repo count
find ~/Developer -name ".git" -type d | wc -l

# check personal repo config
cd ~/Developer/personal/projects/<repo>
git config core.sshCommand

# check work repo config
cd ~/Developer/work/clients/<client>/<repo>
git config core.sshCommand

# run health checks
make doctor
```

Expected:

- personal repos resolve to personal SSH key
- work repos resolve to work SSH key
- `make doctor` passes migration-related checks

## Rollback

Migration creates timestamped backup directories. To rollback:

1. Identify backup path shown by migration output.
2. Move current `~/Developer` aside.
3. Restore backup directory to `~/Developer`.
4. Re-run `make stow`.

## Common Issues

### `validate-repos` reports uncommitted changes

Fix in-place:

```bash
cd <repo>
git add -A
git commit -m "WIP"
# or: git stash
```

### Wrong SSH key after migration

```bash
make stow
make doctor
```

Then inspect `~/.gitconfig`, `.gitconfig-personal`, `.gitconfig-work` includes.

### Shell navigation commands missing

```bash
make stow
exec zsh
```

## Related Commands

- `make validate-repos`
- `make migrate-dev-dryrun`
- `make migrate-dev`
- `make complete-migration`
- `make doctor`

## Related Docs

- `README.md` (high-level structure and commands)
- `docs/doctor-guide.md` (health checks)
- `docs/scripts-reference.md` (script flags and options)
