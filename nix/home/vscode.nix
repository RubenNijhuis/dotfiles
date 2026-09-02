{ pkgs, ... }:

let
  userSettingsDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User"
    else
      ".config/Code/User";
in
{
  # Import this only on graphical desktop hosts. WSL uses native Windows VS
  # Code, so it must not receive an unused Linux configuration directory.
  home.file."${userSettingsDirectory}/settings.json" = {
    source = ../config/vscode/settings.json;
    force = true;
  };
}
