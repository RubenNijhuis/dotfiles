# VS Code Configuration Documentation

Comprehensive guide to the VS Code setup in this dotfiles repository.

## Overview

VS Code settings prioritize a **clean, minimal UI** while enabling modern developer features (Copilot, Claude Code). The configuration focuses on reducing visual clutter while keeping formatting automated through EditorConfig and Biome integration.

## Settings Explained

All settings are in `stow/vscode/Library/Application Support/Code/User/settings.json`.

### Font & Appearance

| Setting | Value | Why |
|---------|-------|-----|
| `editor.fontFamily` | 'Fira Code', Menlo, Monaco | Fira Code enables programming ligatures (→, ≥, !=) |
| `editor.fontLigatures` | `true` | Enable ligatures in editor (e.g., => becomes →) |
| `terminal.integrated.fontLigatures.enabled` | `true` | Apply ligatures in integrated terminal |

### UI Minimalism

| Setting | Value | Why |
|---------|-------|-----|
| `workbench.sideBar.location` | `right` | Sidebar on right reduces cognitive load when reading code |
| `workbench.layoutControl.enabled` | `false` | Hide layout switcher (cleaner title bar) |
| `workbench.startupEditor` | `none` | Don't open welcome screen (faster startup) |
| `workbench.secondarySideBar.defaultVisibility` | `hidden` | Hide secondary sidebar by default |
| `workbench.navigationControl.enabled` | `false` | Hide navigation controls (Back/Forward buttons) |
| `window.commandCenter` | `false` | Disable command center in window title bar |
| `editor.minimap.enabled` | `false` | Disable code minimap (saves render time, cleaner UI) |

### AI Tools

| Setting | Value | Why |
|---------|-------|-----|
| `github.copilot.nextEditSuggestions.enabled` | `true` | Enable Copilot's next-edit suggestions |
| `claudeCode.preferredLocation` | `panel` | Claude Code opens in bottom panel (not sidebar) |
| `chat.commandCenter.enabled` | `false` | Disable chat command center |
| `chat.viewSessions.orientation` | `stacked` | Stack chat sessions vertically |

### Code Formatting

| Setting | Value | Why |
|---------|-------|-----|
| `editor.formatOnSave` | `true` | Auto-format files on save |
| `editor.renderWhitespace` | `all` | Show all whitespace characters (for debugging) |
| `editorconfig.enable` | `true` | Enable EditorConfig integration |

### Language-Specific Formatters

```json
"editor.defaultFormatter": "biomejs.biome"
"[markdown]": { "editor.defaultFormatter": "biomejs.biome" }
"[shellscript]": { "editor.defaultFormatter": "foxundermoon.shell-format" }
```

**Why explicit formatters?**
- Eliminates ambiguity when `formatOnSave` is enabled
- Ensures consistent formatting across team members
- Biome handles JS/TS/JSON/Markdown
- shell-format handles shell scripts

## Installed Extensions

All 18 extensions are documented in `extensions.txt` and declared in `brew/Brewfile.common`.

### AI Tools (3 extensions)

| Extension | Purpose |
|-----------|---------|
| `anthropic.claude-code` | Claude Code AI coding assistant |
| `github.copilot` | GitHub Copilot AI pair programmer |
| `github.copilot-chat` | GitHub Copilot chat interface |

**Why both Claude Code and Copilot?**
- Claude Code: Better for complex reasoning, refactoring, architecture
- Copilot: Better for inline completions, boilerplate code
- Complementary tools, not redundant

### Code Quality & Formatting (4 extensions)

| Extension | Purpose |
|-----------|---------|
| `editorconfig.editorconfig` | EditorConfig support (indentation, line endings) |
| `biomejs.biome` | Fast formatter and linter (JS/TS/JSON/Markdown) |
| `dbaeumer.vscode-eslint` | JavaScript/TypeScript linter |
| `usernamehw.errorlens` | Inline error highlighting (shows errors next to code) |

**Formatting workflow:**
1. EditorConfig handles basics (indent size, line endings, trailing whitespace)
2. Biome handles code style (quotes, semicolons, imports)
3. ESLint handles code quality (unused vars, missing imports)
4. ErrorLens shows all issues inline

### Git (1 extension)

| Extension | Purpose |
|-----------|---------|
| `eamodio.gitlens` | Git supercharged (blame, history, authorship inline) |

**Key features used:**
- Inline blame annotations
- File/line history
- Compare branches/commits
- Visualize commit graph

### Language Support - JavaScript/TypeScript (2 extensions)

| Extension | Purpose |
|-----------|---------|
| `bradlc.vscode-tailwindcss` | Tailwind CSS IntelliSense (autocomplete class names) |
| `svelte.svelte-vscode` | Svelte framework support |

### Language Support - Python (5 extensions)

| Extension | Purpose |
|-----------|---------|
| `ms-python.python` | Full Python language support |
| `ms-python.vscode-pylance` | Python language server (fast static analysis) |
| `ms-python.debugpy` | Python debugger |
| `ms-python.vscode-python-envs` | Python environment management |
| `kevinrose.vsc-python-indent` | Smart Python indentation |

**Why 5 Python extensions?**
- Official Python extension suite from Microsoft
- Each handles a specific aspect (language server, debugging, environments)
- Python requires more setup than JS/TS (virtualenvs, interpreters)

### Language Support - Other (1 extension)

| Extension | Purpose |
|-----------|---------|
| `tamasfe.even-better-toml` | TOML syntax and formatting |

### DevOps & Remote (2 extensions)

| Extension | Purpose |
|-----------|---------|
| `ms-vscode-remote.remote-containers` | Dev containers support |
| `ms-azuretools.vscode-containers` | Docker/container management |

## Setup on New Machine

### 1. Install VS Code

```bash
# Already in Brewfile.common
brew install --cask visual-studio-code
```

### 2. Install Extensions

```bash
# From dotfiles root
make vscode-setup

# Or manually
cat "stow/vscode/Library/Application Support/Code/User/extensions.txt" | \
  grep -v '^#' | grep -v '^$' | cut -d' ' -f1 | \
  xargs -L 1 code --install-extension
```

### 3. Stow Configuration

```bash
# Symlink settings
make stow

# Or manually
stow -d stow -t ~ vscode
```

### 4. Verify Setup

```bash
# Check extensions installed
code --list-extensions

# Check settings applied
cat ~/Library/Application\ Support/Code/User/settings.json
```

## EditorConfig Integration

VS Code respects `.editorconfig` automatically with the EditorConfig extension installed.

**What EditorConfig handles:**
- Indentation (spaces vs tabs, size)
- Line endings (LF vs CRLF)
- Final newlines
- Trimming trailing whitespace
- Character encoding

**What Biome handles:**
- Code style (semicolons, quotes)
- Line length
- Bracket spacing
- Arrow function parens

**Together they provide complete formatting coverage.**

## Formatting Workflow

### Automatic (Recommended)

1. Save file (`Cmd+S`)
2. EditorConfig applies basic formatting
3. Biome applies code style
4. ESLint shows any remaining issues via ErrorLens

### Manual

```bash
# Format all files in repository
make format

# Format on commit (via pre-commit hook)
git commit  # Auto-fixes formatting issues
```

## Troubleshooting

### "Format on save not working"

**Check:**
1. EditorConfig extension installed: `code --list-extensions | grep editorconfig`
2. Biome extension installed: `code --list-extensions | grep biomejs.biome`
3. Settings applied: Verify `editor.formatOnSave: true` in settings.json

**Fix:**
```bash
# Reinstall extensions
code --install-extension editorconfig.editorconfig
code --install-extension biomejs.biome

# Reload VS Code
# Cmd+Shift+P → "Reload Window"
```

### "Wrong formatter applied"

**Issue:** VS Code using wrong formatter for file type

**Check:** Look for `[<language>]` section in settings.json

**Fix:**
```json
"[javascript]": {
  "editor.defaultFormatter": "biomejs.biome"
}
```

### "Settings not syncing to new machine"

**Issue:** VS Code Settings Sync not enabled or stow not applied

**Fix:**
```bash
# Re-stow configuration
make unstow && make stow

# Or manually
stow -d stow -t ~ vscode
```

### "Extensions missing after fresh install"

**Fix:**
```bash
# Install from extensions.txt
make vscode-setup
```

## Performance Tips

**Current optimizations (already applied):**
- Minimap disabled (saves render time)
- No startup editor (faster launch)
- Minimal UI controls (faster rendering)

**Additional optimizations (optional):**

1. **Disable unused language features:**
   ```json
   "[java]": { "editor.suggestOnTriggerCharacters": false }
   ```

2. **Reduce file watcher limit:**
   ```json
   "files.watcherExclude": {
     "**/.git/objects/**": true,
     "**/.git/subtree-cache/**": true,
     "**/node_modules/**": true
   }
   ```

3. **Disable telemetry (privacy + performance):**
   ```json
   "telemetry.telemetryLevel": "off"
   ```

## Customization

### Adding New Extensions

1. Install extension in VS Code
2. Add to `extensions.txt`:
   ```bash
   echo "publisher.extension-name  # Description" >> \
     "stow/vscode/Library/Application Support/Code/User/extensions.txt"
   ```
3. Add to `brew/Brewfile.common`:
   ```bash
   echo 'vscode "publisher.extension-name"' >> brew/Brewfile.common
   ```
4. Commit changes

### Changing Formatter

To use a different formatter:

```json
"[python]": {
  "editor.defaultFormatter": "ms-python.black-formatter"
}
```

### Theme Customization

Current setup uses default VS Code theme. To customize:

```json
"workbench.colorTheme": "Dracula",
"workbench.iconTheme": "material-icon-theme"
```

## Integration with Other Tools

### Git Hooks

Pre-commit hook validates formatting before commits:
- Shellcheck for shell scripts
- Biome for JS/TS/JSON
- Auto-fixes issues and re-stages files

### EditorConfig

`.editorconfig` at repository root defines formatting rules that VS Code follows automatically.

### Makefile

```bash
make vscode-setup  # Install extensions
make format        # Format all files (EditorConfig + Biome)
make doctor        # Verify VS Code configuration
```

## See Also

- `.editorconfig` - Formatting rules
- `biome.json` - Biome configuration
- `docs/editorconfig.md` - EditorConfig documentation
- `docs/scripts-reference.md` - Script flags and options
- `git-hooks/pre-commit` - Pre-commit formatting validation
- `brew/README.md` - Extension management via Homebrew
