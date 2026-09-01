# VS Code Configuration

Settings live in `chezmoi/Library/Application Support/Code/User/settings.json`.
Extensions live beside them in `extensions.txt`. `brew/Brewfile.vscode` is the
legacy extension inventory; keep it in sync while VS Code remains transition-owned.

## Design Choices

- **Minimal UI**: sidebar right, no minimap, no command center, no layout controls
- **Vim keybindings** via vscodevim
- **Relative line numbers** for vim-style navigation
- **Tokyo Night** theme (consistent with Neovim, tmux, terminal)
- **Biome** as default formatter (JS/TS/JSON/Markdown), with language-specific overrides for shell (shell-format), Python (Ruff), and Dockerfile

## Formatter Chain

| Language | Formatter | Linter |
|----------|-----------|--------|
| JS/TS/JSON | Biome | Biome + ESLint |
| Shell | shell-format | ShellCheck |
| Python | Ruff | Ruff |
| Dockerfile | vscode-docker | vscode-docker |
| All others | EditorConfig | — |

## Setup

```bash
chezmoi apply       # materialize the transition-owned settings
make vscode-setup  # install extensions from extensions.txt
```

## Adding Extensions

1. Add the extension ID to `chezmoi/Library/Application Support/Code/User/extensions.txt`
   and `brew/Brewfile.vscode`.
2. Run `make vscode-parity` to verify parity.
