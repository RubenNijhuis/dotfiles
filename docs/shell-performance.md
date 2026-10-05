# Shell startup

The shell is Nix-first and deliberately small. Zsh is the primary interactive
shell; Bash is a compatible fallback. Home Manager owns the startup files and
the shared modules in `nix/config/shell/`.

## What starts immediately

- A deterministic PATH: Nix profiles first, then explicit local runtime and
  macOS exception paths, then system tools.
- Zsh completion setup with a 20-hour `compinit` cache and the declarative
  `fzf-tab` plugin.
- Starship, directory environment loading, aliases, and local untracked
  overrides.

## What is deferred or cached

- Global Mise activation is retired; project runtimes use explicit devShells.
- `zoxide` initializes only when `z` or `zi` is first used.
- Starship, Atuin, GitHub CLI, Docker, and similar `init`/completion output is
  cached under `$XDG_CACHE_HOME/{zsh,bash}`.

Every cached initializer records the resolved executable target as well as its
mtime. This matters for Nix: a profile symlink can keep the same timestamp
while its target changes during a switch. A changed Nix package therefore
rebuilds the cache instead of sourcing generated code that points to a retired
store path.

## Verify and recover

Use a fresh shell after `make nix-switch` and check the prompt plus basic
commands. If a cache ever becomes suspect, run `flush-cache` from the shell
and open a new session. The cache is disposable; it contains generated shell
code, never personal configuration or credentials.

For a simple timing sample:

```bash
time zsh -i -c exit
```

Do not add a global runtime manager merely to speed up startup. An active
project should use a Nix devShell; a temporary local runtime is the exception,
not the baseline.
