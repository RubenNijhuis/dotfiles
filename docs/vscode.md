# VS Code Configuration

Settings in `stow/vscode/Library/Application Support/Code/User/settings.json`.
Extensions in `stow/vscode/.../extensions.txt` and `brew/Brewfile.vscode` (must stay in sync).

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
make stow          # symlink settings
make vscode-setup  # install extensions
```

## Adding Extensions

1. Add to `extensions.txt` and `brew/Brewfile.vscode`
2. Run `make brew-audit` to verify parity
