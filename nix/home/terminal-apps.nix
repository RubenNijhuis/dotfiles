{ ... }:

{
  # Keep the existing rich shell aliases until the full shell handoff. Eza's
  # static theme is still safe to make Nix-owned now.
  home.file.".config/eza/theme.yml".source = ../config/eza/theme.yml;

  programs.btop = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../config/btop/btop.conf) // {
      # A Home Manager link is immutable by design; keep runtime preferences
      # declarative instead of having btop rewrite the file on exit.
      save_config_on_exit = false;
    };
    themes.tokyo-night-custom = ../config/btop/themes/tokyo-night-custom.theme;
  };

  xdg.enable = true;

  programs.lazygit = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
    settings = {
      gui = {
        nerdFontsVersion = "3";
        showBottomLine = false;
        showPanelJumps = false;
        border = "rounded";
        theme = {
          activeBorderColor = [
            "#ff9e64"
            "bold"
          ];
          inactiveBorderColor = [ "#27a1b9" ];
          searchingActiveBorderColor = [
            "#ff9e64"
            "bold"
          ];
          optionsTextColor = [ "#7aa2f7" ];
          selectedLineBgColor = [ "#283457" ];
          cherryPickedCommitFgColor = [ "#7aa2f7" ];
          cherryPickedCommitBgColor = [ "#bb9af7" ];
          markedBaseCommitFgColor = [ "#7aa2f7" ];
          markedBaseCommitBgColor = [ "#e0af68" ];
          unstagedChangesColor = [ "#db4b4b" ];
          defaultFgColor = [ "#c0caf5" ];
        };
      };
      git = {
        pagers = [
          {
            colorArg = "always";
            pager = "delta --paging=never";
          }
        ];
        autoFetch = true;
        autoRefresh = true;
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
      };
      os = {
        editPreset = "";
        edit = "{{editor}} {{filename}}";
        editAtLine = "{{editor}} +{{line}} {{filename}}";
      };
      keybinding.universal = {
        quit = "q";
        quit-alt1 = "<c-c>";
      };
    };
  };
}
