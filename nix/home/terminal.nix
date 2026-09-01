{ pkgs, ... }:

{
  # Home Manager owns the generated startup files. The raw source remains in
  # the repository's chezmoi tree temporarily so the migration is reviewable,
  # but chezmoi ignores the target paths and cannot compete for ownership.
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = builtins.readFile ../config/shell/zshrc;
  };

  programs.bash = {
    enable = true;
    initExtra = builtins.readFile ../config/shell/bashrc;
  };

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../config/starship.toml);
  };

  programs.atuin = {
    enable = true;
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
