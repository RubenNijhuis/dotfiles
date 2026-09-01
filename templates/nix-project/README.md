# Project Nix environment

Copy `flake.nix` into a project that needs the shared Node development
environment. Copy `.envrc.example` to `.envrc`, review it, then run:

```bash
direnv allow
```

The shell activates only in this repository. Customize the `packages` list for
the project instead of adding project-only tools to the global machine profile.
