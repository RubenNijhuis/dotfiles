# EditorConfig

Ensures consistent coding styles across all editors. Settings are in `.editorconfig` at the repo root.

## Key Choices

| Files | Indent | Notes |
|-------|--------|-------|
| Default (`*`) | 2 spaces | UTF-8, LF line endings, trim trailing whitespace, final newline |
| Shell (`*.sh`, `*.bash`, `*.zsh`) | 2 spaces | Keeps deeply nested scripts readable |
| Makefile | Tabs (required) | Make syntax requires tabs |
| JS/TS (`*.js`, `*.ts`, etc.) | 2 spaces | Single quotes, 100 char line length |
| Python (`*.py`) | 4 spaces | PEP 8 / Black formatter standard |
| Ruby / Brewfiles | 2 spaces | Ruby community standard |
| Markdown (`*.md`) | 2 spaces | Trailing whitespace preserved (used for line breaks) |
| Lock files | Untouched | Auto-generated, don't modify |

## Integration

- **EditorConfig** handles basics: indentation, line endings, whitespace
- **Biome** handles code style: semicolons, quotes, imports (JS/TS/JSON)
- Both are applied on save in VS Code and enforced by pre-commit hooks
