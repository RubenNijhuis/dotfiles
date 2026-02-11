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
│   ├── ssh/        # SSH config with personal/work key management
│   ├── gpg/        # GPG config for commit signing
│   ├── vim/        # Vim/Neovim sensible defaults (fallback editor)
│   ├── zsh/        # .zshrc, .zprofile, .zshenv, .p10k.zsh
│   ├── shell/      # ~/.config/shell/{aliases,functions,path,exports}.sh
│   ├── git/        # .gitconfig with personal/work split
│   ├── ghostty/    # Terminal config
│   ├── vscode/     # VS Code settings
│   └── bat/        # bat config
├── templates/      # Setup guides and key generation scripts
│   ├── ssh/        # SSH key setup guide and generator
│   ├── gpg/        # GPG key setup guide and generator
│   └── launchd/    # LaunchD agent templates for scheduled tasks
├── brew/           # Brewfile.common, Brewfile.personal, Brewfile.work
├── macos/          # macOS defaults script
├── scripts/        # Helper scripts (stow, update, ssh-info, gpg-info, etc.)
├── docs/           # Extended documentation and examples
├── assets/         # Wallpapers, etc.
└── local/          # Machine-specific overrides (gitignored)
```

## Commands

```bash
make help          # Show all commands
make install       # Full setup
make update        # Update brew + re-stow
make stow          # Stow all packages
make unstow        # Unstow all packages
make macos         # Apply macOS defaults
make ssh-info      # Display SSH key information and status
make gpg-info      # Display GPG configuration and signing status
make ssh-setup     # Generate SSH keys for current profile
make gpg-setup     # Generate GPG key and configure signing
make migrate-ssh   # Migrate existing SSH keys to new naming
```

## Personal / Work Split

**Git identity** — single email for all development:
- All repos use `contact@rubennijhuis.com`
- GPG signing enabled by default

**Brew packages** — separate Brewfiles per profile (personal/work), selected at install time.
This is where the real split happens - work profile doesn't install Steam, personal does, etc.

**Shell overrides** — add machine-specific config to `~/.config/shell/local.sh` (gitignored).

## SSH & GPG Configuration

### SSH Keys

SSH configuration uses profile-aware keys that automatically select based on repository location:

- **Personal key**: `~/.ssh/id_ed25519_personal` (used in `~/personal/*`)
- **Work key**: `~/.ssh/id_ed25519_work` (used in `~/work/*`)
- **Configuration**: `~/.ssh/config` with modular includes

**Generate keys:**
```bash
make ssh-setup
```

**View status:**
```bash
make ssh-info
```

**Migrate existing keys:**
```bash
make migrate-ssh
```

Keys are automatically selected based on repository location. No manual key selection needed!

### GPG Commit Signing

All Git commits are automatically signed using GPG for verification on GitHub/GitLab.

**Generate key:**
```bash
make gpg-setup
```

**View configuration:**
```bash
make gpg-info
```

**Setup steps:**
1. Generate GPG key (prompted during install or run `make gpg-setup`)
2. Add public key to GitHub: Settings → SSH and GPG keys → New GPG key
3. Commits are automatically signed in all repositories

See `templates/ssh/README.md` and `templates/gpg/README.md` for detailed documentation.

## Automation with LaunchD

Automated scheduled tasks using macOS's native LaunchD system (superior to cron).

### Quick Start

**Install all scheduled tasks:**
```bash
~/dotfiles/scripts/install-launchd-agents.sh
```

**Install specific task:**
```bash
~/dotfiles/scripts/install-launchd-agent.sh obsidian-sync
```

**List installed tasks:**
```bash
~/dotfiles/scripts/list-launchd-agents.sh
```

### Current Automated Tasks

- **Obsidian Sync** (`obsidian-sync`): Daily git backup of Obsidian vault at 8 PM
  - Auto-commits and pushes changes
  - Logs: `~/.local/log/obsidian-sync.log`
  - Manual run: `~/dotfiles/scripts/sync-obsidian.sh`

### Adding New Scheduled Tasks

It's trivial to add new scheduled tasks! See `templates/launchd/README.md` for:
- Complete step-by-step guide
- Common scheduling patterns (daily, weekly, intervals, specific days)
- Script templates (logging, error handling, git sync, cleanup, health checks)
- Troubleshooting guide
- Quick reference commands

See `docs/launchd-examples.md` for 10 complete working examples:
- Database backups
- Multi-repository git sync
- Downloads folder cleanup
- System health monitoring
- Time Machine verification
- Homebrew auto-updates
- Log rotation
- API health checks
- Screenshot organization
- Battery monitoring

### Vim/Neovim

Basic, sensible vim configuration for when VS Code isn't available (servers, containers, SSH sessions):

**Features:**
- Modern defaults (relative line numbers, syntax highlighting, smart search)
- 2-space indentation matching your other configs
- VS Code-compatible keybindings (Ctrl+S to save)
- Filetype-specific settings (JS/TS: 2 spaces, Python: 4 spaces, Go: tabs)
- Shared config between vim and neovim

**Config files:**
- `~/.vimrc` - Main vim configuration
- `~/.config/nvim/init.vim` - Neovim sources the main vimrc

No plugins, no complexity - just sensible defaults for quick edits.

## Adding a New Stow Package

1. Create a directory under `stow/` mirroring the target path relative to `~`:
   ```
   stow/mytool/.config/mytool/config
   ```
2. Run `make stow` — this creates `~/.config/mytool/config` as a symlink.
