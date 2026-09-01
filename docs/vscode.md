# VS Code Configuration

Settings and the extension manifest live in `nix/config/vscode/`. Home Manager
links both into VS Code's native macOS location. `brew/Brewfile.vscode` is a
historical inventory only; the Nix manifest is the source of truth.

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
make nix-switch     # materialize the Nix-owned settings and manifest
make vscode-setup   # install extensions from the manifest
```

## Adding Extensions

1. Add the extension ID to `nix/config/vscode/extensions.txt`.
2. Run `make vscode-setup` to install it, then `make vscode-parity` to compare
   against the historical inventory during the transition.
