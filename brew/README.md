# Brewfile Management

Organized Homebrew package management with split Brewfiles for better maintainability.

## Structure

```
brew/
├── Brewfile.cli       # CLI tools (brew formulae)
├── Brewfile.bootstrap # empty compatibility placeholder
├── Brewfile.core      # temporary Nix-unavailable GUI exception
├── Brewfile.design    # temporary Apple-Silicon Nix exception
├── Brewfile.media     # temporary broken-Nix-package exception
├── Brewfile.apps      # historical GUI inventory; never a default install
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

### Brewfile.bootstrap

An empty compatibility placeholder for older installer/profile references.
Nix now owns ChezMoi (temporarily during the path migration) and the useful
Zsh plugins. New profiles should not include this file.

### Brewfile.core

The narrow Homebrew exception for a fresh Mac. Zen is currently the only
everyday application without a compatible Nix package. Thunderbird, Obsidian,
Signal, VS Code, and cmux are Nix-owned. The specialist design/media
exceptions are documented separately below.

```bash
brew bundle --file=brew/Brewfile.core
```

### Brewfile.apps
**GUI applications:**
- Core apps (Claude, VS Code, Chrome, Obsidian, Ghostty)
- Fonts (Fira Code, Nerd Fonts)
- Communication (Discord, Signal, Slack, WhatsApp)
- Media & Entertainment (Spotify, Steam, rekordbox)
- Creative tools (Affinity, Processing)
- Development (Rider, DBeaver, gcloud)

### Nix capability applications

Krita and RawTherapee are Nix-managed on Linux, but the current pinned Krita
package does not support Apple Silicon macOS, so `Brewfile.design` is their
documented Mac exception. HandBrake remains in `Brewfile.media` because its
current pinned Nix package is marked broken on macOS. Revisit both exceptions
after a Nixpkgs update. Homebrew remains only for these documented
Nix-unavailable or Nix-broken macOS exceptions.

### Brewfile.vscode
**VS Code extensions:**
- Language support, formatters, linters
- Git tools, themes, keybindings

## Commands

### Install packages
```bash
# Install the active lean profile
make install

# Or install the current Homebrew exception manually
brew bundle --file=brew/Brewfile.core
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
   - Available in Nix? → add it to the appropriate Nix capability module
   - Nix-unavailable everyday GUI app? → `Brewfile.core`
   - Specialist GUI app? → keep it out of the default profile and record it in
     `Brewfile.apps` only as migration inventory
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
