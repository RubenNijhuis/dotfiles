{ pkgs, ... }:

let
  yaziConfig = ../config/yazi;
in
{
  # These tools share the interactive navigation workflow. Keep their data
  # (zoxide's database and tmux-resurrect state) local; Nix owns binaries and
  # deterministic configuration only.
  home.packages = with pkgs; [
    fzf
    sesh
    zoxide
  ];

  home.file.".config/sesh/sesh.toml".source = ../config/sesh/sesh.toml;

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    enableZshIntegration = false;
    extraPackages = with pkgs; [
      bat
      file
    ];
    settings = builtins.fromTOML (builtins.readFile "${yaziConfig}/yazi.toml");
    keymap = builtins.fromTOML (builtins.readFile "${yaziConfig}/keymap.toml");
    theme = builtins.fromTOML (builtins.readFile "${yaziConfig}/theme.toml");
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    prefix = "C-a";
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    focusEvents = true;
    historyLimit = 50000;
    escapeTime = 0;
    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
      vim-tmux-navigator
    ];

    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -ag terminal-overrides ",*:Smulx=\\E[4::%p1%dm"
      set -ag terminal-overrides ",*:Setulc=\\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m"
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g set-clipboard on
      set -g allow-passthrough on

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
      bind c new-window -c "#{pane_current_path}"
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'if command -v pbcopy >/dev/null 2>&1; then pbcopy; elif command -v wl-copy >/dev/null 2>&1; then wl-copy; elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard; fi'
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"
      bind-key "T" run-shell "sesh connect \"$(sesh list | fzf-tmux -p 55%,60% --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' --bind 'tab:down,btab:up' --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)')\""

      set -g status-position top
      set -g status-interval 5
      set -g status-style "bg=#1a1b26,fg=#c0caf5"
      set -g status-left-length 30
      set -g status-left "#[fg=#1a1b26,bg=#7aa2f7,bold] #S #[fg=#7aa2f7,bg=#1a1b26]"
      set -g status-right-length 50
      set -g status-right "#[fg=#414868]#[fg=#c0caf5,bg=#414868] %H:%M #[fg=#7aa2f7,bg=#414868]#[fg=#1a1b26,bg=#7aa2f7,bold] %d-%b "
      set -g window-status-format "#[fg=#414868,bg=#1a1b26]#[fg=#a9b1d6,bg=#414868] #I:#W #[fg=#414868,bg=#1a1b26]"
      set -g window-status-current-format "#[fg=#7aa2f7,bg=#1a1b26]#[fg=#1a1b26,bg=#7aa2f7,bold] #I:#W #[fg=#7aa2f7,bg=#1a1b26]"
      set -g window-status-separator ""
      set -g pane-border-style "fg=#414868"
      set -g pane-active-border-style "fg=#7aa2f7"
      set -g message-style "fg=#c0caf5,bg=#292e42"
      set -g message-command-style "fg=#c0caf5,bg=#292e42"
    '';
  };
}
