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

Automatic entry is optional: only if using direnv, copy `.envrc.example` to
`.envrc`, inspect it, then run `direnv allow`. No hook is enabled by default.
