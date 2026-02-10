# Dotfiles

Personal macOS development environment managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone https://github.com/<user>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script will:
- Ask for a profile (`personal` or `work`)
- Install Homebrew and packages
- Symlink all configs via Stow
- Set up Node (fnm) and Bun
- Optionally apply macOS defaults

## Structure

```
dotfiles/
├── stow/           # Config packages (each dir = one Stow package)
│   ├── zsh/        # .zshrc, .zprofile, .zshenv, .p10k.zsh
│   ├── shell/      # ~/.config/shell/{aliases,functions,path,exports}.sh
│   ├── git/        # .gitconfig with personal/work split
│   ├── ghostty/    # Terminal config
│   ├── vscode/     # VS Code settings
│   └── bat/        # bat config
├── brew/           # Brewfile.common, Brewfile.personal, Brewfile.work
├── macos/          # macOS defaults script
├── scripts/        # stow-all, unstow-all, update
├── assets/         # Wallpapers, etc.
└── local/          # Machine-specific overrides (gitignored)
```

## Commands

```bash
make help       # Show all commands
make install    # Full setup
make update     # Update brew + re-stow
make stow       # Stow all packages
make unstow     # Unstow all packages
make macos      # Apply macOS defaults
```

## Personal / Work Split

**Git identity** — automatic via directory convention:
- Repos in `~/personal/` use your personal email
- Repos in `~/work/` use your work email
- Configured via `includeIf` in `.gitconfig`

**Brew packages** — separate Brewfiles per profile, selected at install time.

**Shell overrides** — add machine-specific config to `~/.config/shell/local.sh` (gitignored).

## Adding a New Stow Package

1. Create a directory under `stow/` mirroring the target path relative to `~`:
   ```
   stow/mytool/.config/mytool/config
   ```
2. Run `make stow` — this creates `~/.config/mytool/config` as a symlink.
