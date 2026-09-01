{ inputs, ... }:

{
  # Community-maintained Zen flake with a Home Manager module for macOS and
  # Linux. Keep browser state (history, sessions, logins and extensions)
  # user-owned; this profile only manages the application and default handler.
  imports = [ inputs.zen-browser.homeModules.twilight ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    darwinDefaultsId = "app.zen-browser.zen";
  };
}
