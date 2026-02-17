# Brewfile Management

Organized Homebrew package management with split Brewfiles for better maintainability.

## Structure

```
brew/
├── Brewfile.common    # Packages shared across all profiles (personal + work)
├── Brewfile.personal  # Personal-only packages
├── Brewfile.work      # Work-only packages
└── README.md          # This file
```

## Organization

### Brewfile.common
**Packages used on both personal and work machines:**
- Shell & Terminal tools (zsh plugins, fzf, zoxide)
- Core CLI tools (bat, eza, ripgrep, etc.)
- Development tools (fnm, pnpm, shellcheck, rust)
- Security (gnupg, pinentry-mac)
- Core apps (Claude, VS Code, Chrome, Obsidian)
- VS Code extensions

### Brewfile.personal
**Personal projects and hobbies:**
- Browsers (Firefox, Zen)
- Communication (Discord, Signal, WhatsApp)
- Media & Entertainment (Spotify, Steam, rekordbox)
- Creative tools (Affinity, Processing)
- Gaming (Epic Games, Arduino)

### Brewfile.work
**Work-specific tools:**
- Development (Docker, .NET, database CLIs)
- IDEs (Rider, DBeaver)
- Cloud tools (gcloud-cli)
- Collaboration (Slack, Figma, Linear)

## Commands

### Install packages
```bash
# Install common + profile-specific packages
make install

# Or manually
brew bundle --file=brew/Brewfile.common
brew bundle --file=brew/Brewfile.personal  # or Brewfile.work
```

### Add new packages

**Option 1: Add to Brewfile first, then install**
```bash
# Edit appropriate Brewfile
echo 'brew "wget"' >> brew/Brewfile.common

# Install
brew bundle --file=brew/Brewfile.common
```

**Option 2: Install first, then add to Brewfile**
```bash
# Install package
brew install wget

# Sync to Brewfile (interactive)
make brew-sync
```

### Audit Brewfiles
```bash
# Check for discrepancies
make brew-audit
```

Shows:
- Packages installed but not in Brewfiles (orphaned)
- Packages declared but not installed (missing)

### Update packages
```bash
# Update everything
make update

# Or just Homebrew
brew update && brew upgrade
```

## Categories in Brewfiles

All packages are organized into logical categories with comments:

```ruby
# -----------------------------------------------------------------------------
# Category Name
# -----------------------------------------------------------------------------
brew "package-name"  # Description of what it does
cask "app-name"      # Description
```

**Standard categories:**
- **Taps** - Third-party Homebrew taps
- **Shell & Terminal** - Shell plugins, themes, terminal tools
- **Core CLI Tools** - Essential command-line utilities
- **Development Tools** - Programming languages, package managers
- **Security & Privacy** - Encryption, password tools
- **System Utilities** - Maintenance, system tools
- **Fonts** - Programming fonts
- **Core Applications** - Desktop apps
- **VS Code Extensions** - Editor extensions

## Best Practices

### Adding Packages
1. **Use comments** - Explain why each package exists
   ```ruby
   brew "jq"  # JSON processor for API work
   ```

2. **Choose the right file**
   - Used on all machines? → `Brewfile.common`
   - Personal hobby only? → `Brewfile.personal`
   - Work client requirement? → `Brewfile.work`

3. **Keep categories organized**
   - Add to existing category if one fits
   - Create new category for 3+ related packages

### Removing Packages
1. **Remove from Brewfile first**
2. **Then uninstall**
   ```bash
   brew uninstall package-name
   ```
3. **Clean up dependencies**
   ```bash
   brew autoremove
   ```

### Maintenance
```bash
# Monthly audit
make brew-audit

# Clean up old versions
brew cleanup

# Check for issues
brew doctor
```

## Dependencies

Homebrew automatically installs dependencies. These are NOT listed in Brewfiles:
- System libraries (openssl, readline, etc.)
- Formula dependencies (python for packages that need it)
- Build tools (gcc, make, etc.)

The `brew-audit` script filters these out automatically.

## Troubleshooting

### "Package already installed"
```bash
# Force reinstall
brew reinstall package-name
```

### "Cask conflicts with formula"
Some packages exist as both:
```bash
# Remove one
brew uninstall package-name
brew uninstall --cask package-name
```

### "Tap not available"
```bash
# Add tap manually
brew tap username/repo
```

### Orphaned packages after profile switch
Normal! Personal machine may have work tools installed. Options:
1. Keep them (they work fine)
2. Add to current profile's Brewfile
3. Uninstall if truly not needed

## Package Categories Explained

### Why these categories?

**Shell & Terminal** - Tools you use every shell session
- Affects daily workflow efficiency
- Includes completions, themes, fuzzy finders

**Core CLI Tools** - Replace or enhance standard Unix tools
- bat > cat, eza > ls, ripgrep > grep
- Significantly faster or more user-friendly

**Development Tools** - Language runtimes and toolchains
- Node (fnm), Python (via system), Rust, etc.
- Build tools, linters, formatters

**System Utilities** - macOS-specific or system maintenance
- Cleanup tools, LLM runtimes, CLI interfaces

**Applications** - GUI programs
- IDEs, browsers, productivity apps
- Casks only (formulae are CLI)

## Examples

### Adding a new tool
```bash
# 1. Decide which Brewfile
# Tool used on all machines → Brewfile.common
# Personal hobby project → Brewfile.personal

# 2. Find the right category
# It's a CLI tool → "Core CLI Tools"

# 3. Add with comment
echo 'brew "httpie"  # Better HTTP client' >> brew/Brewfile.common

# 4. Install
brew bundle --file=brew/Brewfile.common
```

### Cleaning up unused packages
```bash
# 1. Audit
make brew-audit

# 2. Review "Installed but not in Brewfiles"

# 3. Either:
# - Add to Brewfile if you want to keep it
# - Uninstall if you don't need it
brew uninstall unused-package
```

### Syncing between machines
```bash
# Machine A (has new packages)
git add brew/Brewfile.*
git commit -m "Add new packages"
git push

# Machine B (needs updates)
git pull
brew bundle --file=brew/Brewfile.common
brew bundle --file=brew/Brewfile.personal
```

## See Also

- `make brew-sync` - Sync installed packages to Brewfiles
- `make brew-audit` - Check Brewfile sync status
- `make update` - Update all packages
- `scripts/sync-brew.sh` - Interactive sync script
- `scripts/brew-audit.sh` - Audit script source
