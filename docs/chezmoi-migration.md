# chezmoi migration

Chezmoi owns the remaining home-configuration source state under `chezmoi/`.
The live ownership and Nix handoff status are maintained only in the
[Nix ownership matrix](nix-ownership-matrix.md), so this document stays
focused on chezmoi-specific mechanics. Its machine-local configuration is:

```toml
sourceDir = "~/Developer/personal/dotfiles/chezmoi"
```

## Edge cases learned

- **0-byte source files are silently skipped** unless you prefix with
  `empty_` (so `.hushlogin` → `empty_dot_hushlogin`).
- **Anything in `chezmoi/` maps to `$HOME`.** Putting `README.md` in the
  source state would copy it to `~/README.md` on apply. Doc lives in
  `docs/` instead.
- **`~/.config/chezmoi/chezmoi.toml` is machine-local**, not committed.
  Each machine needs `sourceDir = "<absolute path to this repo>/chezmoi"`.
- **Executable bits use a filename prefix.** `executable_foo.sh` in the
  source state becomes `~/foo.sh` with `+x`. Hit by Claude's statusline.
- **Nested `.git` directories are not source state.** Do not copy an
  application-managed `.git` directory into chezmoi.
- **`private_` prefix on a directory sets 0700.** Used for `.ssh/` and
  `.gnupg/`. On a file: 0600. Chezmoi enforces these on every apply.
- **Library paths under `~/Library/...` need no encoding.** "Library"
  doesn't start with a dot, so it nests inside `chezmoi/Library/...`
  directly. Used for ghostty and VS Code.

## Templates + machine-local data

`chezmoi/dot_config/shell/local.sh.tmpl` is the first tracked template.
It renders into `~/.config/shell/local.sh` using values from
`~/.config/chezmoi/chezmoi.toml`:

```toml
sourceDir = "~/Developer/personal/dotfiles/chezmoi"

[data.machine]
  obsidian_vault_path = "/Users/.../obsidian-store"
[data.secrets]
  linear_api_key = "..."
```

The template references `{{ .machine.* }}` and `{{ .secrets.* }}`. The
structure is version-controlled; only the values stay machine-local.
Add new machine-specific shell config by extending the .tmpl and
adding the corresponding entry under `[data.machine]` or `[data.secrets]`.
