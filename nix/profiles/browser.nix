{ inputs, ... }:

{
  # Zen Twilight is deliberately separate from the existing stable-release
  # profile. Nix owns the preview browser and default handler; Zen owns its
  # history, sessions, logins, extensions, and Sync state.
  imports = [ inputs.zen-browser.homeModules.twilight ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    darwinDefaultsId = "app.zen-browser.zen";
  };

  # Import this non-secret template through Web Clipper's settings. Never
  # manage the extension database or its optional AI credentials with Nix.
  xdg.configFile."obsidian-web-clipper/research-source.json".source =
    ../config/obsidian-web-clipper/research-source.json;
}
