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

Registered extensions are skipped only when their located `package.json` is
readable. A verified missing payload gets a repair attempt through VS Code's official CLI;
inspection or permission failures return an error, never trigger a reinstall.
Installs are checked afterward; `--check` and `--dry-run` never install or repair.
If VS Code skips a stale registration as already installed, verification fails;
unregister/reinstall that exact extension deliberately rather than deleting metadata.
Unlisted extensions are never automatically uninstalled. The manifest declares
IDs, not immutable versions: marketplace extensions and their updates remain
an explicit application-managed exception to Nix reproducibility.

Container Tools (`ms-azuretools.vscode-containers`) owns Dockerfile formatting.
The old Docker extension ID is now an extension-pack wrapper, not a formatter.
Markdown uses the already-declared Prettier extension; the current Biome
installation does not format Markdown with the shared configuration.
Keep project-specific language extensions outside the portable baseline unless
they become recurring needs. Lua supports this repository's Neovim configuration;
Nginx support is useful for retained Codam and Roodjong configurations. The
2026-10-13 source audit found no Ruby, Go, Zig or .NET source/manifests in the
reviewed personal/work trees (archive, Mave and ThreeJS were excluded); this
supports their approved retirement, not proving future nonuse. Ruby, Go, Zig,
C# Dev Kit, C# and the .NET runtime extension were uninstalled through VS Code;
their unregistered directories await application-managed cleanup. C# and C# Dev
Kit depend on the .NET runtime extension, so review the three as a group.
Astro support (`astro-build.astro-vscode`) was installed for the active website,
which already recommends it in its workspace. It remains a project-specific
extension, not another requirement for every desktop.

The manifest check verifies registration and a readable payload, not runtime
activation of every extension. All 22 declared IDs passed the payload check.
The undeclared Nginx extension's stale registration was repaired with approval
through unregister/reinstall; its 0.3.5 payload is now present and readable.
Two unregistered Claude extension directories were moved to recoverable Trash;
extension-state databases and unrelated caches were left untouched.
Settings remain an active Nix-store link on this Mac.
