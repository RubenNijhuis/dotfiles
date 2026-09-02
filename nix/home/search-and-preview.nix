{ ... }:

{
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--max-columns=150"
      "--max-columns-preview"
      "--glob=!.git"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "tokyonight_night";
      style = "numbers,changes";
      italic-text = "always";
      map-syntax = [
        "*.conf:INI"
        ".gitignore_global:Git Ignore"
        "Brewfile*:Ruby"
        "*.plist:XML"
        "Makefile*:Makefile"
      ];
    };
  };

  # The selected theme is configuration, not mutable application state.
  xdg.configFile."bat/themes/tokyonight_night.tmTheme".source =
    ../config/bat/themes/tokyonight_night.tmTheme;
}
