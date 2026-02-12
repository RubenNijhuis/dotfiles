# Doctor Command Guide

The `make doctor` command provides comprehensive health checks for your dotfiles setup. It validates that all components are properly configured and working correctly.

## Quick Start

```bash
# Run full health check
make doctor

# Quick check (skip optional checks)
make doctor-quick
```

## What Gets Checked

### 1. Stow Configuration ✓

**Validates:**
- All 9 stow packages are present (bat, ghostty, git, gpg, shell, ssh, vim, vscode, zsh)
- No broken symlinks in home directory
- Config files properly linked

**Common issues:**
```bash
# Fix: Re-stow all packages
make unstow && make stow
```

### 2. SSH Configuration ✓

**Validates:**
- Personal SSH key exists: `~/.ssh/id_ed25519_personal`
- Work SSH key exists: `~/.ssh/id_ed25519_work` (optional)
- Keys have correct permissions (600)
- SSH config includes are loaded
- SSH agent status

**Common issues:**
```bash
# Generate missing keys
make ssh-setup

# Fix permissions
chmod 600 ~/.ssh/id_ed25519_personal
chmod 600 ~/.ssh/id_ed25519_work

# Load keys in agent
ssh-add ~/.ssh/id_ed25519_personal
ssh-add ~/.ssh/id_ed25519_work
```

### 3. GPG Configuration ✓

**Validates:**
- GPG secret key exists
- Git signing is configured (`user.signingkey`)
- Commit signing is enabled (`commit.gpgsign = true`)
- GPG agent is working (test sign operation)

**Common issues:**
```bash
# Generate GPG key
make gpg-setup

# Restart GPG agent
pkill gpg-agent
gpgconf --launch gpg-agent

# View GPG info
make gpg-info
```

### 4. Git Configuration ✓

**Validates:**
- Conditional includes are configured in `.gitconfig`
- Personal repos use `id_ed25519_personal` key
- Work repos use `id_ed25519_work` key
- Automatic SSH key selection works

**How it works:**
```bash
# In personal repo
cd ~/Developer/personal/projects/dotfiles
git config core.sshCommand
# Output: ssh -i ~/.ssh/id_ed25519_personal

# In work repo
cd ~/Developer/work/clients/project
git config core.sshCommand
# Output: ssh -i ~/.ssh/id_ed25519_work
```

**Common issues:**
```bash
# Re-stow git config
cd ~/dotfiles && make stow

# Verify conditional includes
git config --list --show-origin | grep includeIf
```

### 5. Shell Configuration ✓

**Validates:**
- Shell config files exist (`.zshrc`, `functions.sh`, `aliases.sh`)
- Functions are defined in `~/.config/shell/functions.sh`
- Aliases are defined in `~/.config/shell/aliases.sh`
- PATH includes: fnm, Bun, Homebrew

**Expected functions:**
- `proj` - Fuzzy find and jump to projects
- `newproj` - Create new project
- `devp`, `deve`, `devl`, `devw`, `deva` - Navigate to directories

**Common issues:**
```bash
# Re-stow shell config
cd ~/dotfiles && make stow

# Reload shell
source ~/.zshrc

# Or open new terminal window
```

### 6. Developer Directory ✓

**Validates:**
- Directory structure exists:
  - `~/Developer/personal/{projects,experiments,learning}`
  - `~/Developer/work/{projects,clients}`
  - `~/Developer/archive`
- Counts repositories per category
- Old `repositories/` folder is removed

**Expected structure:**
```
~/Developer/
├── personal/
│   ├── projects/      (11 repos)
│   ├── experiments/   (11 repos)
│   └── learning/      (2 repos)
├── work/
│   └── clients/       (4 repos)
└── archive/           (17 repos)
```

**Common issues:**
```bash
# Complete migration if old structure exists
make complete-migration

# Create structure manually
mkdir -p ~/Developer/{personal/{projects,experiments,learning},work/{projects,clients},archive}
```

### 7. Runtime Environments ✓

**Validates:**
- Node.js installed via fnm
- Bun installed
- Reports versions

**Common issues:**
```bash
# Install Node.js
fnm install --lts

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Reload shell after Bun install
source ~/.zshrc
```

### 8. LaunchD Agents ⚠ (Optional)

**Validates:**
- User agents loaded (counts them)
- Specific agent status (e.g., `com.user.obsidian-sync`)
- Log directory exists (`~/.local/log/`)

**Skipped in quick mode** (`make doctor-quick`)

**Common issues:**
```bash
# Create log directory
mkdir -p ~/.local/log

# List loaded agents
launchctl list | grep com.user

# Load agent manually
launchctl load ~/Library/LaunchAgents/com.user.obsidian-sync.plist

# View agent logs
tail -f ~/.local/log/obsidian-sync.log
```

### 9. Homebrew ⚠ (Optional)

**Validates:**
- Homebrew installed
- Reports version
- Checks for outdated packages
- Shows profile (personal/work)

**Skipped in quick mode** (`make doctor-quick`)

**Common issues:**
```bash
# Update packages
brew upgrade

# Update Homebrew itself
brew update

# Check for issues
brew doctor
```

## Exit Codes

The doctor command uses standard exit codes:

- **0** - All checks passed
- **1** - Warnings found (non-critical issues)
- **2** - Errors found (critical issues)

Use in scripts:
```bash
if make doctor; then
  echo "System healthy!"
else
  echo "Issues found, check output above"
fi
```

## Advanced Usage

### Check Specific Section

```bash
# Not yet implemented - run full doctor for now
make doctor
```

### In CI/CD

```bash
# Quick check in CI pipeline
make doctor-quick

# Fail pipeline on errors
if ! make doctor-quick; then
  echo "Dotfiles health check failed!"
  exit 1
fi
```

### Debugging

```bash
# Run with verbose output
bash -x ~/dotfiles/scripts/doctor.sh

# Check specific components manually
make ssh-info   # SSH keys
make gpg-info   # GPG configuration
make validate-repos  # Git repositories
```

## Common Scenarios

### After Fresh Install

```bash
./install.sh
make doctor
```

Expected: All checks should pass ✓

### After Migration

```bash
make migrate-dev
make doctor
```

Expected: Developer directory structure validated, all repos counted

### Before Committing Changes

```bash
# Make changes to dotfiles
make doctor
git add .
git commit -m "Update configuration"
```

Expected: Verify changes don't break system

### Troubleshooting Issues

```bash
make doctor
# Read suggestions
# Apply fixes
make doctor  # Re-check
```

Example output when issues exist:
```
Summary
-------
7 checks passed
2 warnings found
1 error found

Suggested fixes:
- Generate work SSH key: make ssh-setup
- Reload shell: source ~/.zshrc
- Update packages: brew upgrade
```

## Understanding Results

### ✓ Green Checkmark
Component is working correctly, no action needed.

### ⚠ Yellow Warning
Component has minor issues or optional features not configured.
- Work SSH key missing (only needed if you have work repos)
- Outdated Homebrew packages (not critical)
- SSH keys not loaded in agent (still works, just slower)

### ✗ Red X
Critical issue that may prevent functionality.
- Missing SSH keys
- Broken symlinks
- Missing config files
- Git conditional includes not working

## Integration with Other Commands

**Workflow:**

1. **Install** - `./install.sh`
2. **Verify** - `make doctor`
3. **Fix issues** - Follow suggestions
4. **Re-verify** - `make doctor`
5. **Backup** - `make backup`
6. **Update** - `make update`
7. **Re-verify** - `make doctor`

## FAQ

**Q: Should I run doctor before or after install?**
A: After. The install script sets everything up, then doctor verifies it worked.

**Q: How often should I run doctor?**
A:
- After initial install
- After migrations
- When troubleshooting
- Before committing dotfiles changes
- After system updates

**Q: What's the difference between doctor and doctor-quick?**
A: Quick mode skips optional checks (LaunchD agents, Homebrew packages). Use it for faster validation when those components aren't critical.

**Q: Can doctor fix issues automatically?**
A: No, doctor only detects issues and suggests fixes. You must run the suggested commands manually.

**Q: What if doctor reports false positives?**
A: File an issue! Doctor should accurately reflect system state. Some warnings are intentional (e.g., work key optional).

**Q: Does doctor work on Linux?**
A: Partially. Some checks are macOS-specific (LaunchD). Most checks (Stow, SSH, GPG, Git) work on Linux.

**Q: Can I use doctor in automated scripts?**
A: Yes! Check exit codes:
```bash
if make doctor-quick; then
  deploy_application
else
  abort_deployment
fi
```

## Troubleshooting Doctor

**Doctor script not found:**
```bash
# Ensure you're in dotfiles directory
cd ~/dotfiles

# Script should be executable
chmod +x scripts/doctor.sh

# Run directly
bash scripts/doctor.sh
```

**Color codes not showing:**
```bash
# Use a terminal that supports ANSI colors
# Ghostty, iTerm2, Terminal.app all work
```

**Script errors:**
```bash
# Check bash version (needs 4.0+)
bash --version

# Run with debugging
bash -x ~/dotfiles/scripts/doctor.sh
```

## See Also

- `make ssh-info` - Detailed SSH key information
- `make gpg-info` - Detailed GPG configuration
- `make validate-repos` - Git repository validation
- `make help` - All available commands
- `README.md` - Main documentation
- `docs/developer-migration.md` - Migration guide
