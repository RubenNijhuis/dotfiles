{ ... }:

{
  # Home Manager is the sole owner of generated shell startup files.
  programs.zsh = {
    enable = true;
    # Keep completion packages/fpath, but let the cached startup own compinit.
    completionInit = "";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = builtins.readFile ../config/shell/zshrc;
  };

  programs.bash = {
    enable = true;
    initExtra = builtins.readFile ../config/shell/bashrc;
  };

  # Homebrew remains available only for documented macOS exceptions. Keep its
  # environment setup declarative while the exception path still exists.
  home.file.".zprofile" = {
    source = ../config/shell/zprofile;
    force = true;
  };

  programs.starship = {
    enable = true;
    # Our cached startup initializes these once in each interactive shell.
    enableZshIntegration = false;
    enableBashIntegration = false;
    settings = builtins.fromTOML (builtins.readFile ../config/starship.toml);
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    enableBashIntegration = false;
    flags = [ "--disable-up-arrow" ];
    settings = {
      style = "compact";
      inline_height = 20;
      enter_accept = true;
      filter_mode_shell_up_key_binding = "session";
      search_mode = "fuzzy";
      filter_mode = "directory";
      show_preview = true;
      history_filter = [
        "^ls$"
        "^cd "
        "^clear$"
        "^exit$"
        "^pwd$"
      ];
      sync.records = false;
    };
  };
}
