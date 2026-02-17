# EditorConfig Documentation

Ensures consistent coding styles across all editors and team members.

## What is EditorConfig?

EditorConfig helps maintain consistent coding styles between different editors and IDEs. When you open a file, your editor reads the `.editorconfig` file and applies the settings automatically.

## Supported Editors

**Works out of the box:**
- VS Code (with EditorConfig extension)
- Neovim/Vim (with plugin)
- JetBrains IDEs (Rider, WebStorm, PyCharm, etc.)
- Sublime Text
- Atom
- Many others

## Installation

### VS Code
Already configured via `brew/Brewfile.common`:
```ruby
vscode "editorconfig.editorconfig"
```

### Neovim
Add to your config:
```vim
Plug 'editorconfig/editorconfig-vim'
```

### Vim
Install manually:
```bash
git clone https://github.com/editorconfig/editorconfig-vim.git ~/.vim/pack/plugins/start/editorconfig-vim
```

## Settings Overview

### Default (All Files)
```ini
[*]
charset = utf-8          # Use UTF-8 encoding
end_of_line = lf         # Unix-style line endings
insert_final_newline = true  # Add newline at end of file
trim_trailing_whitespace = true  # Remove trailing spaces
indent_style = space     # Use spaces (not tabs)
indent_size = 2          # 2 spaces per indent
```

### Shell Scripts
```ini
[*.{sh,bash,zsh}]
indent_style = space
indent_size = 2          # 2-space indentation for shells
```

**Why 2 spaces?**
- Shell scripts are often deeply nested
- 2 spaces keeps code readable without excessive indentation
- Matches common shell script conventions

### Makefiles
```ini
[Makefile]
indent_style = tab       # Makefiles REQUIRE tabs
indent_size = 4
```

**Important:** Makefiles break with spaces. EditorConfig ensures tabs are used.

### JavaScript / TypeScript
```ini
[*.{js,jsx,ts,tsx}]
indent_style = space
indent_size = 2
quote_type = single      # Use single quotes
max_line_length = 100
```

### Python
```ini
[*.py]
indent_style = space
indent_size = 4          # PEP 8 standard
max_line_length = 88     # Black formatter default
```

**Why 4 spaces?**
- Python PEP 8 standard
- Better readability for Python's significant whitespace
- Matches Black formatter

### Ruby / Brewfiles
```ini
[{Brewfile,Brewfile.*,*.rb}]
indent_style = space
indent_size = 2          # Ruby community standard
```

### Markdown
```ini
[*.md]
trim_trailing_whitespace = false  # Preserve trailing spaces
```

**Why preserve trailing spaces?**
- Markdown uses two trailing spaces for line breaks
- Trimming breaks intentional formatting

### Lock Files
```ini
[{yarn.lock,pnpm-lock.yaml}]
insert_final_newline = false  # Don't modify lock files
```

**Why not modify?**
- Lock files are auto-generated
- Changes can cause git conflicts
- Package managers expect specific format

## File Type Coverage

The `.editorconfig` includes settings for:

**Shell & Config:**
- `.sh`, `.bash`, `.zsh` - Shell scripts
- `.yml`, `.yaml` - YAML configs
- `.json`, `.jsonc` - JSON files
- `.toml` - TOML configs
- `Makefile` - Make build files

**Programming:**
- `.js`, `.jsx`, `.ts`, `.tsx` - JavaScript/TypeScript
- `.py` - Python
- `.rb`, `Brewfile` - Ruby
- `.rs` - Rust
- `.go` - Go

**Markup & Docs:**
- `.md` - Markdown
- `.html`, `.xml`, `.svg` - Markup

**Styles:**
- `.css`, `.scss`, `.sass`, `.less`

**Package Managers:**
- `package.json`, `yarn.lock`, `pnpm-lock.yaml`
- `Cargo.toml`, `Cargo.lock`
- `Gemfile`, `Gemfile.lock`

## Testing EditorConfig

### Check if it's working
1. Open a `.sh` file in VS Code
2. Press `Tab` - should insert 2 spaces
3. Save file - should trim trailing whitespace

### Verify settings
```bash
# Check what settings apply to a file
editorconfig .zshrc
```

If `editorconfig` CLI is not installed:
```bash
npm install -g editorconfig
```

## Common Issues

### "Tab key inserts tabs instead of spaces"
**Solution:** Ensure EditorConfig extension is installed and enabled.

VS Code:
```bash
code --install-extension editorconfig.editorconfig
```

### "Settings not applying"
**Troubleshooting:**
1. Check extension is installed
2. Reload editor
3. Ensure `.editorconfig` is in project root
4. Check file glob pattern matches your file

### "Makefile indentation broken"
**Issue:** Some editors override EditorConfig for Makefiles.

**Solution:** Check editor-specific Makefile settings and disable them.

### "Trailing spaces still there"
**Issue:** `.md` files preserve trailing spaces by design.

**Solution:** This is intentional for Markdown line breaks. Use `<br>` tags if you want forced line breaks without trailing spaces.

## Best Practices

### 1. Keep It in Root
Place `.editorconfig` in the repository root with `root = true`. This prevents editors from looking in parent directories.

### 2. Be Specific
Use specific globs for file types:
```ini
# Good
[*.{js,jsx,ts,tsx}]

# Less good
[*.js]
[*.jsx]
[*.ts]
[*.tsx]
```

### 3. Comment Your Choices
Explain non-obvious settings:
```ini
[*.md]
trim_trailing_whitespace = false  # Preserve for line breaks
```

### 4. Match Formatters
Align with your formatters (Biome, Black, rustfmt):
```ini
[*.py]
max_line_length = 88  # Matches Black formatter
```

### 5. Test With Team
Different editors may interpret settings differently. Test with your team's editors.

## Integration with Other Tools

### Biome
EditorConfig works alongside Biome:
- EditorConfig handles basic formatting (indentation, line endings)
- Biome handles code formatting (imports, semicolons, quotes, etc.)
- Both respect each other's settings

### ESLint
ESLint can read EditorConfig settings:
```json
{
  "extends": ["plugin:editorconfig/all"]
}
```

### Black (Python)
Black respects `max_line_length` from EditorConfig.

## Override Precedence

**Most specific wins:**
1. `.editorconfig` in current directory
2. `.editorconfig` in parent directories
3. Editor default settings

**File patterns:**
```ini
[*]              # Least specific (all files)
[*.js]           # More specific (JS files)
[src/**/*.js]    # Most specific (JS in src/)
```

## Git Configuration

EditorConfig ensures consistent line endings:
```ini
[*]
end_of_line = lf  # Unix line endings
```

This overrides `.gitattributes` in your editor.

## Examples

### Adding a New Language
```ini
# Add at appropriate section
[*.{vue,svelte}]
indent_style = space
indent_size = 2
```

### Project-Specific Override
Create a subdirectory `.editorconfig`:
```ini
# In subfolder: legacy-code/.editorconfig
root = false  # Inherit from parent

[*.js]
indent_size = 4  # Override for legacy code
```

### Disable for Specific Files
```ini
[{dist/**,build/**}]
# No settings = no formatting changes
```

## Resources

- **Official Site:** https://editorconfig.org
- **Supported Properties:** https://editorconfig.org/#supported-properties
- **Editor Plugins:** https://editorconfig.org/#download
- **File Format Spec:** https://editorconfig-specification.readthedocs.io

## Troubleshooting Commands

```bash
# Test EditorConfig file syntax
editorconfig --version

# Check settings for a file
editorconfig /path/to/file.js

# VS Code: Check EditorConfig output
# Command Palette -> "Developer: Show Output" -> Select "EditorConfig"
```

## See Also

- `biome.json` - JS/TS/JSON/Markdown formatting rules
- `.eslintrc` - JavaScript linting rules
- `.shellcheckrc` - Shell script linting rules
