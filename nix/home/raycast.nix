{ lib, ... }:

let
  preferredApplications = {
    browser = "Zen Browser (Twilight)";
    calendar = "Calendar";
    code = "Visual Studio Code";
    convert = "HandBrake";
    design = "Affinity";
    draw = "Krita";
    mail = "Thunderbird";
    message = "Signal";
    music = "Spotify";
    notes = "Obsidian";
    raw = "RawTherapee";
    terminal = "cmux";
    video = "DaVinci Resolve";
  };

  launcherCommands = lib.mapAttrs' (
    command: application:
    lib.nameValuePair ".config/raycast/script-commands/${command}.sh" {
      executable = true;
      text = ''
        #!/bin/bash

        # Required parameters:
        # @raycast.schemaVersion 1
        # @raycast.title ${command}
        # @raycast.mode silent

        # Optional parameters:
        # @raycast.packageName Preferred Applications
        # @raycast.description Open ${application}

        exec /usr/bin/open -a ${lib.escapeShellArg application}
      '';
    }
  ) preferredApplications;
in
{
  # Raycast does not expose application aliases as a supported declarative
  # format. Script Commands provide the same root-search workflow as plain,
  # reviewable files. Raycast needs this directory registered once per Mac.
  home.file = launcherCommands;
}
