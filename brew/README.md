# Brewfile Management

Organized Homebrew package management with split Brewfiles for better maintainability.

## Structure

```
brew/
├── Brewfile.cli       # CLI tools (brew formulae)
├── Brewfile.apps      # GUI applications (casks + fonts)
├── Brewfile.vscode    # VS Code extensions
└── README.md          # This file
```

## Organization

### Brewfile.cli
**CLI tools:**
- Shell & Terminal tools (zsh plugins, Starship, Atuin, fzf, zoxide, ghq, sesh)
- Core CLI tools (bat, eza, ripgrep, etc.)
- Development tools (fnm, pnpm, shellcheck, rust)
- Security (gnupg, pinentry-mac)
- System utilities (dockutil, ollama)

### Brewfile.apps
**GUI applications:**
- Core apps (Claude, VS Code, Chrome, Obsidian, Ghostty)
- Fonts (Fira Code, Nerd Fonts)
- Communication (Discord, Signal, Slack, WhatsApp)
- Media & Entertainment (Spotify, Steam, rekordbox)
- Creative tools (Affinity, Processing)
- Development (Rider, DBeaver, gcloud)

### Brewfile.vscode
**VS Code extensions:**
- Language support, formatters, linters
- Git tools, themes, keybindings

## Commands

### Install packages
```bash
# Install all packages
make install

# Or manually
brew bundle --file=brew/Brewfile.cli
brew bundle --file=brew/Brewfile.apps
brew bundle --file=brew/Brewfile.vscode
```

### Add new packages

**Option 1: Add to Brewfile first, then install**
```bash
# Edit appropriate Brewfile
echo 'brew "wget"' >> brew/Brewfile.cli

# Install
brew bundle --file=brew/Brewfile.cli
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

## Best Practices

### Adding Packages
1. **Use comments** - Explain why each package exists
   ```ruby
   brew "jq"  # JSON processor for API work
   ```

2. **Choose the right file**
   - CLI tool? → `Brewfile.cli`
   - GUI app? → `Brewfile.apps`
   - VS Code extension? → `Brewfile.vscode`

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

## See Also

- `make brew-sync` - Sync installed packages to Brewfiles
- `make brew-audit` - Check Brewfile sync status
- `make update` - Update all packages
- `ops/sync-brew.sh` - Interactive sync script
- `ops/brew-audit.sh` - Audit script source
