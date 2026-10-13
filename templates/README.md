# Project Nix environment

For a code project whose declared engines match Node 24 and the pinned pnpm:

```bash
nix flake init -t ~/Developer/personal/dotfiles#node
nix develop
```

Run from the project directory. Commit its `flake.nix` **and** `flake.lock`;
update that lock independently. The template is already pinned, so initializing
does not silently select today's Nixpkgs. Its documentation lives outside the
template directory to avoid conflicting with an existing project's README.

Customize the packages for that project instead of growing the global machine
profile. Use the Git-aware repository reference above, not a raw `path:`
reference, so ignored local configuration never enters the Nix store.
For an exact package-manager version, check the project's
`packageManager` declaration rather than assuming the template matches it.
Check `node --version` and `pnpm --version` **inside** the project shell.
pnpm can select a different signed release from its cache to honor that
declaration; this is application-managed tooling, not an exact Nix package pin.
Provision it while online before relying on offline use. Do not disable
signature verification or rewrite a project's version to match the global one.

Use pnpm by default for new personal JavaScript projects. Set an exact
`packageManager` version in `package.json` and commit `pnpm-lock.yaml`.
pnpm 12 can add a separate package-manager document to that lock; retain it
alongside the application graph. Use `pnpm install --frozen-lockfile` for
reproducible installs and `pnpm exec` for project-installed tools. Prefer a
pinned devDependency over repeatedly fetching an unpinned `npx`/`pnpm dlx` tool.

Before converting npm/Yarn, inspect CI, containers, framework helpers and Nix
derivations. `pnpm import` translates compatible locks, not runtimes; verify
the dependency graph and actual workflow before retiring the old lock with
approval. Keep an exception for an integration that still requires its original
manager. Never alias npm/yarn to pnpm or remove npm from Node's installation.

Automatic entry is optional: only if using direnv, copy `.envrc.example` to
`.envrc`, inspect it, then run `direnv allow`. No hook is enabled by default.
