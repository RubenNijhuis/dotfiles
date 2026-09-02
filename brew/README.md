# Homebrew exceptions

Nix is the default package owner. This directory records only applications
that the pinned Nix package set cannot currently provide on Apple Silicon
macOS. It is not a general package inventory or a second installer.

```text
brew/
├── Brewfile.design    # Krita and RawTherapee
├── Brewfile.media     # HandBrake
├── Brewfile.gaming    # Prism Launcher and its Java runtime
└── Brewfile.services  # deliberately chosen local-service exception
```

Each file is an explicit capability choice. Install one only when the Mac
needs it:

```bash
brew bundle --file=brew/Brewfile.design
```

Before adding an exception, verify that the pinned Nix package does not work
on this host, use a named capability file, and write a short reason beside the
entry. Do not add generic CLI tools here; put portable tooling in a Nix profile
or use a project `devShell`.

`make brew-audit` checks the exception files selected by the local machine
profile. It never imports all locally installed Homebrew packages into this
repository.
