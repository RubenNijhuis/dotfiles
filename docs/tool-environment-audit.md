# Tool and environment audit

This is a read-only snapshot of the current MacBook, taken 2026-08-31. It
describes evidence, not an automatic removal list.

## Findings

| Signal | Result | Interpretation |
| --- | --- | --- |
| Homebrew formulas installed | 237 | Includes transitive dependencies; not a useful measure of tools to keep. |
| Formula declarations in the legacy Brewfile | 89 | The legacy declaration is broad and no longer matches the installed state. |
| Homebrew casks installed | 10 | Most visible GUI applications were installed by other means. |
| GUI casks declared | 44 | The historical GUI Brewfile is an inventory, not a valid fresh-machine baseline. |
| VS Code extensions declared | 31 | It spans many languages and is not evidence that each runtime belongs globally. |
| Current managed runtimes | Node 24.18.0, Ruby 4.0.5 via mise | Node is the only runtime supported by current project evidence. |
| Global npm / user Python packages | none found | Good: there is no hidden package sprawl to preserve. |
| Recently changed config areas | chezmoi, mise, nvim, tmux, starship, shell, sesh, Yazi, Atuin, GitHub, gcloud, cmux, Spicetify | This is the actual candidate day-to-day toolkit. |

## Project evidence

Excluding dependency and build directories, the local developer tree contains
44 JavaScript/TypeScript manifests and 6 Rust manifests. It has no detected
Python, Go, .NET, Ruby, Zig, Lua, or Arduino project manifests. Almost all
repositories outside `personal/dotfiles` have their latest commit in 2024 or
earlier; the Pay SDK is dated 2026-02-25 and needs a deliberate keep/archive
decision rather than inference.

## Environment decision

| Layer | Keep / add | Reason |
| --- | --- | --- |
| Shared base | Git, GitHub CLI, chezmoi during transition, shell, Starship, fzf, ripgrep, fd, eza, bat, jq/yq, tmux, Yazi, direnv, Nix tooling | Useful across macOS, Linux, and WSL. |
| Default development | JavaScript/TypeScript: Node LTS and pnpm | The current evidence supports it on every host. |
| Opt-in language modules | Rust, Python/uv, Go | Available, but not installed until an active project asks for them. |
| Project only | Framework CLIs, databases, Docker tooling, SDKs, formatters, test runners | Define in `devShell`s per active project, not globally. |
| Platform-only | Xcode, OrbStack, application launchers, GUI database/design/media apps | Keep out of shared Nix modules. |
| Review before retaining | gcloud, LM Studio/Ollama, Spicetify, cmux, all 31 VS Code extensions, old Java/.NET tooling | Config recency is a useful hint, not proof of current need. |

## Proposed cleanup sequence

1. Do not uninstall installed formulae or apps yet.
2. Move the shared base to Nix after the first successful activation.
3. Make JavaScript the only automatically selected language environment.
4. Add a `devShell` when reopening a project; only then activate Rust, Python,
   Go, database, or cloud tooling for that project.
5. Review one GUI/tool category at a time after 30 days of actual use.
6. Archive or classify the old developer repositories before deciding which
   historical runtimes can disappear.

The legacy Homebrew bootstrap has already stopped declaring Lua, .NET, Go,
Python/uv/Ruff, Rust, Zig, pnpm, and global formatters. This affects a future
bootstrap only; it does not uninstall the tools currently on the MacBook.
