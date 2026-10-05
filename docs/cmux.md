# cmux

On macOS, Home Manager owns rendering through `nix/config/ghostty/config`
and application preferences through `nix/home/cmux.nix`. Sessions and private
application data stay local. These preferences are not installed on Linux or WSL.

The baseline uses Tokyo Night and FiraCode Nerd Font, stable workspace order,
notification badges without pane flashes, and external links through the system
browser (Zen). Claude integration is disabled. Edit the Nix sources rather than
the generated files or the corresponding Settings controls.

## Apply

Run `make nix-build` first. For the initial handoff, run
`make nix-adopt PROFILE=cmux` to preserve existing files as `.pre-nix`, then
`make nix-switch`. Reload cmux with `Cmd+Shift+,`. Rendering changes may require
a new terminal surface. New source files must be tracked by Git before using
these Git-flake commands; a local `path:.` flake can evaluate untracked files.

## Migration state

The full Home Manager generation now owns these files, including the cmux CLI
helper. Prior configurations remain at `~/.config/cmux/cmux.json.pre-nix`,
`~/.config/shell/cmux.sh.pre-nix`, and `~/.config/shell/functions.sh.pre-cmux`.
GC roots from the earlier targeted handoff remain under
`~/.local/state/nix/gcroots/`; they are no longer the active ownership mechanism.
Existing shells can load the update with `source ~/.config/shell/functions.sh`.

## Daily use

- `proj`: choose a repository, including Git worktrees. Inside cmux this opens
  a named workspace at its directory; run `nvim .` or split a shell as needed.
  Outside cmux it opens the configured editor, as before.
- `proj /path/to/project`: skip the picker.
- `notify-run make test`: run a command and notify its cmux workspace when it
  exits. The original exit status is preserved; command arguments are never
  copied into notifications. Outside cmux it simply runs the command.

The pinned Nix package's `cmux` executable launches the GUI. The macOS module
provides a shell function through `~/.config/shell/cmux.sh` that calls the bundled
CLI instead. This is loaded by the shared functions module in Bash and Zsh.

- `Cmd+D`: split right; `Cmd+Shift+D`: split down.
- `Cmd+Shift+Return`: zoom the current split.
- `Cmd+I`: notifications; `Cmd+Shift+U`: jump to an unread workspace.
- Use cmux workspaces for local projects. Keep tmux/sesh for remote or detached
  sessions; nesting tmux is optional.

Notification display is configured here; commands must still emit notifications.
No agent is automatically launched and no agent hooks are installed.

Configuration reference: <https://cmux.com/docs/configuration>.
