# Developer Directory Migration Guide

This guide walks you through migrating from the old flat `~/Developer/repositories/` structure to the new organized `~/Developer/` structure with automatic work/personal detection.

## Overview

**What this migration does:**
- Reorganizes 44 repositories into categorized structure (projects/experiments/learning/archive)
- Renames all repos to kebab-case for consistency
- Sets up automatic SSH key selection based on directory
- Preserves all git history and remotes
- Creates automatic backup before making changes

**What you'll get:**
```
Before: ~/Developer/repositories/     After: ~/Developer/
├── Celebratix/                       ├── personal/
├── Codam/                            │   ├── projects/      (11 repos)
├── Experiments/                      │   ├── experiments/   (11 repos)
├── Projects/                         │   └── learning/      (2 repos)
├── Portfolio22                       ├── work/
├── SRC-API                           │   └── clients/
└── ... (44 repos, mixed naming)      │       └── celebratix/ (4 repos)
                                      └── archive/
                                          └── codam/         (17 repos)
```

## Pre-Migration Checklist

### Step 1: Ensure All Changes Are Committed

The migration script validates that all repos are safe to move. Based on the current state, you have uncommitted/unpushed changes in these repos:

**Uncommitted files:**
- `obsidian-store`: 1 file (`.claude/settings.local.json`)
- `celebratix-dashboard`: 4 files
- `celebratix-widget`: 1 file
- `ctm`: 1 file

**Unpushed commits:**
- `celebratix-backend`: 28 commits
- `ctm`: 5 commits

**Action required:**

```bash
# Handle obsidian-store
cd ~/Developer/repositories/obsidian-store
git add .claude/settings.local.json
git commit -m "Update Claude settings"
git push

# Handle celebratix repos
cd ~/Developer/repositories/Celebratix/celebratix-backend
git push  # Push 28 commits

cd ~/Developer/repositories/Celebratix/celebratix-dashboard
git add .
git commit -m "WIP: dashboard changes"
git push

cd ~/Developer/repositories/Celebratix/celebratix-widget
git add .
git commit -m "WIP: widget changes"
git push

cd ~/Developer/repositories/Celebratix/ctm
git add .
git commit -m "WIP: ctm changes"
git push  # Push 5 commits
```

### Step 2: Update Dotfiles

Make sure you have the latest dotfiles changes:

```bash
cd ~/dotfiles
git pull
make stow
source ~/.zshrc  # Reload shell functions
```

### Step 3: Create Manual Backup (Optional but Recommended)

While the migration script creates automatic backups, you can create an additional manual backup:

```bash
cp -r ~/Developer ~/Developer-backup-manual-$(date +%Y%m%d-%H%M%S)
```

## Migration Process

### Step 1: Validate Repos

Run the validation script to ensure all repos are safe to migrate:

```bash
cd ~/dotfiles
make validate-repos
```

**Expected output (after handling uncommitted changes):**
```
==> Validating repositories in ~/Developer/repositories/

Checking 44 repositories...

✓ All repositories validated successfully!

Summary:
  Total repositories: 44
  Clean repositories: 44
  Uncommitted changes: 0
  Unpushed commits: 0
  Stashed changes: 0

All repositories are safe to migrate!
```

If you see any warnings, go back to Step 1 of the Pre-Migration Checklist.

### Step 2: Preview Migration (Dry Run)

Preview what the migration will do without making any changes:

```bash
make migrate-dev-dryrun
```

**Expected output:**
```
==> Developer Directory Migration (DRY RUN)

Creating backup: ~/Developer-backup-20260212-153045

Personal Projects (11 repos):
  Would move: Portfolio22 → ~/Developer/personal/projects/portfolio22
  Would move: SRC-API → ~/Developer/personal/projects/src-api
  Would move: dotfiles → ~/Developer/personal/projects/dotfiles
  ... (8 more)

Personal Experiments (11 repos):
  Would move: Experiments/apollo → ~/Developer/personal/experiments/apollo
  Would move: Experiments/basque → ~/Developer/personal/experiments/basque
  ... (9 more)

Personal Learning (2 repos):
  Would move: Projects/the-farmer-was-replaced → ~/Developer/personal/learning/the-farmer-was-replaced
  Would move: effect/cheffect → ~/Developer/personal/learning/cheffect

Work - Celebratix (4 repos):
  Would move: Celebratix/celebratix-backend → ~/Developer/work/clients/celebratix/celebratix-backend
  ... (3 more)

Archive - Codam (17 repos):
  Would move: Codam/born2beroot → ~/Developer/archive/codam/born2beroot
  ... (16 more)

Migration summary:
  Total repos: 44
  Personal projects: 11
  Personal experiments: 11
  Personal learning: 2
  Work projects: 4
  Archive: 17
```

Review the output carefully. Check that repos are going to the right categories.

### Step 3: Execute Migration

Once you're satisfied with the preview, run the actual migration:

```bash
make migrate-dev
```

**The script will:**
1. Create automatic backup at `~/Developer-backup-TIMESTAMP/`
2. Create new directory structure under `~/Developer/`
3. Move each repo with progress updates
4. Verify git integrity after each move
5. Display final summary

**Example progress output:**
```
==> Developer Directory Migration

Creating backup: ~/Developer-backup-20260212-153045
✓ Backup created

Creating directory structure...
✓ Created ~/Developer/personal/projects
✓ Created ~/Developer/personal/experiments
✓ Created ~/Developer/personal/learning
✓ Created ~/Developer/work/clients
✓ Created ~/Developer/archive

Migrating Personal Projects (11/44)...
  ✓ Moved portfolio22
  ✓ Moved src-api
  ...

Migration complete!

Summary:
  Total repos migrated: 44
  Personal projects: 11
  Personal experiments: 11
  Personal learning: 2
  Work projects: 4
  Archive: 17

Backup location: ~/Developer-backup-20260212-153045
```

## Post-Migration Verification

### Step 1: Verify Repo Count

Ensure all 44 repos were migrated:

```bash
find ~/Developer -name ".git" -type d | wc -l
```

**Expected:** `44`

### Step 2: Test Personal Repo

Verify git config and SSH key selection work for personal repos:

```bash
cd ~/Developer/personal/projects/portfolio22
git config user.email          # Should show: contact@rubennijhuis.com
git config core.sshCommand     # Should include: id_ed25519_personal
git fetch                       # Should work without prompting
```

### Step 3: Test Work Repo

Verify work repos use the correct SSH key:

```bash
cd ~/Developer/work/clients/celebratix/celebratix-backend
git config user.email          # Should show: contact@rubennijhuis.com
git config core.sshCommand     # Should include: id_ed25519_work
git fetch                       # Should work without prompting
```

### Step 4: Test Shell Functions

Verify new navigation commands work:

```bash
proj   # Should open fzf with all 43 projects
devp   # Should cd to ~/Developer/personal/projects
deve   # Should cd to ~/Developer/personal/experiments
devl   # Should cd to ~/Developer/personal/learning
devw   # Should cd to ~/Developer/work
deva   # Should cd to ~/Developer/archive
```

### Step 5: Test New Project Creation

Try creating a new project:

```bash
newproj test-migration experiment personal
cd ~/Developer/personal/experiments/test-migration
git log  # Should show "Initial commit"
ls -la   # Should show README.md

# Clean up test project
cd ..
rm -rf test-migration
```

### Step 6: Verify Git Remotes

Check a few repos to ensure remotes are intact:

```bash
cd ~/Developer/personal/projects/dotfiles
git remote -v  # Should show your dotfiles repo

cd ~/Developer/work/clients/celebratix/celebratix-backend
git remote -v  # Should show Celebratix remote
```

## Troubleshooting

### Issue: "Repository has uncommitted changes"

**Problem:** Migration script refuses to run because repos have uncommitted changes.

**Solution:** Go back to Pre-Migration Checklist Step 1 and commit/push all changes.

### Issue: "SSH key not working after migration"

**Problem:** Git operations fail with permission denied errors.

**Solution:**
```bash
# Test SSH connection
ssh -T git@github.com

# If fails, check SSH agent
ssh-add -l

# Add keys if needed
ssh-add ~/.ssh/id_ed25519_personal
ssh-add ~/.ssh/id_ed25519_work
```

### Issue: "Git config not showing correct SSH key"

**Problem:** `git config core.sshCommand` doesn't show expected key.

**Solution:**
```bash
# Verify conditional includes are active
git config --list --show-origin | grep includeIf

# Should see entries like:
# file:/Users/you/.gitconfig	includeif.gitdir:~/Developer/work/.path=~/.gitconfig-work
# file:/Users/you/.gitconfig	includeif.gitdir:~/Developer/personal/.path=~/.gitconfig-personal

# If missing, re-stow git configs
cd ~/dotfiles
make stow
```

### Issue: "proj command not found"

**Problem:** Shell functions not available.

**Solution:**
```bash
# Reload shell configuration
source ~/.zshrc

# Or open a new terminal window
```

### Issue: "Wrong repos in wrong categories"

**Problem:** Some repos went to the wrong category during migration.

**Solution:**
```bash
# Move manually
mv ~/Developer/personal/projects/wrong-repo ~/Developer/work/projects/

# Or restore from backup and re-run with modifications
```

## Rollback Instructions

If something goes wrong and you need to rollback:

### Option 1: Restore from Migration Backup

```bash
# Find your backup
ls -la ~/Developer-backup-*

# Restore (example with timestamp)
rm -rf ~/Developer
mv ~/Developer-backup-20260212-153045 ~/Developer
```

### Option 2: Restore from Manual Backup

If you created a manual backup:

```bash
rm -rf ~/Developer
mv ~/Developer-backup-manual-20260212-120000 ~/Developer
```

### Option 3: Selective Restore

If only specific repos are problematic:

```bash
# Copy specific repo from backup
cp -r ~/Developer-backup-20260212-153045/repositories/portfolio22 ~/Developer/repositories/
```

## Cleanup

Once you've verified everything works correctly:

### Step 1: Remove Old Structure

```bash
# Remove the old repositories folder (now empty)
rm -rf ~/Developer/repositories
```

### Step 2: Keep Backup for Safety

Keep the automatic backup for at least 1 week:

```bash
# After 1 week, if everything is working fine:
rm -rf ~/Developer-backup-*
```

### Step 3: Commit Dotfiles Changes

If you made any manual adjustments during migration:

```bash
cd ~/dotfiles
git status
git add .
git commit -m "chore: complete Developer directory migration"
git push
```

## Advanced Usage

### Manually Moving Individual Repos

If you need to recategorize a repo after migration:

```bash
# Move from experiments to projects
mv ~/Developer/personal/experiments/my-repo ~/Developer/personal/projects/

# Move from personal to work
mv ~/Developer/personal/projects/my-repo ~/Developer/work/projects/

# Git config will automatically adjust based on new location
cd ~/Developer/work/projects/my-repo
git config core.sshCommand  # Now uses work key
```

### Adding New Categories

To add a new category (e.g., `~/Developer/personal/prototypes`):

```bash
mkdir -p ~/Developer/personal/prototypes

# Update proj() function in ~/.config/shell/functions.sh to include new path
# Add to the fd search paths:
~/Developer/personal/prototypes \
```

### Batch Operations

Find all repos with specific characteristics:

```bash
# Find all repos with uncommitted changes
find ~/Developer -name ".git" -type d -execdir sh -c '
  cd "{}" && cd .. &&
  git diff-index --quiet HEAD -- || echo "Uncommitted: $(pwd)"
' \;

# Find all repos with unpushed commits
find ~/Developer -name ".git" -type d -execdir sh -c '
  cd "{}" && cd .. &&
  git log --branches --not --remotes | head -n 1 && echo "Unpushed: $(pwd)"
' \;

# Find all repos from specific organization
find ~/Developer -name ".git" -type d -execdir sh -c '
  cd "{}" && cd .. &&
  git remote -v | grep "celebratix" && echo "Found: $(pwd)"
' \;
```

## FAQ

**Q: Can I run the migration multiple times?**
A: No, the script is designed for a one-time migration. If you need to re-run it, first restore from backup.

**Q: Will this affect my git history?**
A: No, git history is preserved. Moving a repository directory doesn't affect the `.git` folder contents.

**Q: What if I have repos outside ~/Developer/repositories/?**
A: The migration script only handles `~/Developer/repositories/`. Move other repos manually after migration.

**Q: Can I customize the migration mapping?**
A: Yes, edit `scripts/migrate-developer-structure.sh` before running. The mapping is defined in the script's main logic.

**Q: What happens to git worktrees?**
A: Git worktrees may break if they reference absolute paths. You'll need to recreate them after migration.

**Q: Will IDE configurations break?**
A: Some IDEs store absolute paths to project directories. You may need to re-open projects in VS Code, IntelliJ, etc.

**Q: What about npm/node_modules symlinks?**
A: Node modules should work fine. If you encounter issues, just `rm -rf node_modules && npm install`.

## Summary

**Before migration:**
- Commit and push all changes in repos
- Update dotfiles and reload shell
- Optionally create manual backup

**During migration:**
- Validate with `make validate-repos`
- Preview with `make migrate-dev-dryrun`
- Execute with `make migrate-dev`

**After migration:**
- Verify repo count (43 expected)
- Test git operations in personal and work repos
- Test shell functions (proj, devp, deve, etc.)
- Verify SSH keys work correctly
- Keep backup for 1 week, then delete

**If problems occur:**
- Restore from backup
- Check troubleshooting section
- Review verification steps

Your repos will be organized, automatically configured, and easy to navigate! 🚀
