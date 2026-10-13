# VS Code Configuration

Settings and the extension manifest live in `nix/config/vscode/`. Home Manager
links settings into VS Code's native location on graphical desktop hosts.
The repository manifest is the sole tracked extension list; the setup command
installs its extensions through VS Code, not Nix. WSL uses native Windows VS Code.

## Design Choices

- **Minimal UI**: sidebar right, no minimap, no command center, no layout controls
- **Vim keybindings** via vscodevim
- **Relative line numbers** for vim-style navigation
- **Tokyo Night** theme (consistent with Neovim, tmux, terminal)
- **Biome** as default formatter (JS/TS/JSON), with overrides for Markdown (Prettier), shell (shell-format), Python (Ruff), and Dockerfile (Container Tools)

## Formatter Chain

| Language | Formatter | Linter |
|----------|-----------|--------|
| JS/TS/JSON | Biome | Biome + ESLint |
| Markdown | Prettier | — |
| Shell | shell-format | ShellCheck |
| Python | Ruff | Ruff |
| Dockerfile | Container Tools | Container Tools |

EditorConfig supplies whitespace conventions, not a formatter for other languages.

## Setup

```bash
make nix-switch     # materialize the Nix-owned settings
make vscode-setup   # install extensions from the manifest
make vscode-setup ARGS=--check    # read-only check; non-zero if anything is missing
make vscode-setup ARGS=--dry-run  # preview missing installs
```

## Adding Extensions

1. Add the extension ID to `nix/config/vscode/extensions.txt`.
2. Run `make vscode-setup` to install it on the current machine.

Already-installed extensions are skipped; failures return a non-zero status.
Unlisted extensions are never automatically uninstalled. The manifest declares
IDs, not immutable versions: marketplace extensions and their updates remain
an explicit application-managed exception to Nix reproducibility.

Container Tools (`ms-azuretools.vscode-containers`) owns Dockerfile formatting.
The old Docker extension ID is now an extension-pack wrapper, not a formatter.
Markdown uses the already-declared Prettier extension; the current Biome
installation does not format Markdown with the shared configuration.
The 2026-10-13 audit found all 22 declared IDs installed and eight undeclared
language extensions; these extras were left untouched, not promoted into the
portable baseline. Settings are an active Nix-store link on this Mac.
