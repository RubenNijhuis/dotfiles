# Brewfile Management

Homebrew is a small escape hatch for documented macOS-only exceptions. Nix is
the default package owner.

## Structure

```
brew/
├── Brewfile.cli       # formulae with no current Nix replacement
├── Brewfile.design    # Krita and RawTherapee on Apple Silicon
├── Brewfile.media     # HandBrake while its Nix package is broken on macOS
├── Brewfile.gaming    # Prism Launcher and its required Java runtime
├── Brewfile.services  # deliberately local service exceptions
└── README.md          # This file
```

## Organization

`Brewfile.cli` covers formulae that remain practical macOS exceptions. The
four capability files contain only the applications that cannot currently be
provided by the pinned Nix package set on this Mac. VS Code extensions are
declared in `nix/config/vscode/extensions.txt`, not through Homebrew.

## Commands

### Install packages
```bash
# Install the active lean profile
make install

# Or opt into one documented specialist exception manually
brew bundle --file=brew/Brewfile.design
```

### Add new packages

**Option 1: Add to Brewfile first, then install**
```bash
# Prefer a Nix profile. If no Nix package works on macOS, add the exception
# to a named Brewfile with a comment explaining why.

# Install
brew bundle --file=brew/Brewfile.cli
```

**Option 2: Install first, then add to Brewfile**
```bash
# Audit before changing an exception manifest
make brew-audit
```

### Audit selected exceptions
```bash
# Check for discrepancies
make brew-audit
```

The audit only evaluates the selected profile's exception files. It does not
turn every application installed on a machine into a global baseline.

### Update packages
```bash
# Update everything
make update

# Or just Homebrew
brew update && brew upgrade
```

## Best Practices

### Adding Packages
1. **Use Nix first.** Add a package to the appropriate Nix profile whenever
   the pinned cross-platform package works.
2. **Use comments** - Explain why each Homebrew exception exists.
   ```ruby
   brew "jq"  # JSON processor for API work
   ```

3. **Choose the right file.** Use `Brewfile.cli` only for formulae; place a
   GUI app in a narrow, named capability file. VS Code extensions go in the
   Nix-owned extension manifest.

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

- `make brew-sync` - Review formulae and taps; it never auto-adds GUI apps
- `make brew-audit` - Check Brewfile sync status
- `make update` - Update all packages
- `ops/sync-brew.sh` - Interactive sync script
- `ops/brew-audit.sh` - Audit script source
