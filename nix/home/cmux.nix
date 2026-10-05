{ lib, pkgs, ... }:

{
  # Home Manager owns preferences; cmux owns sessions and application data.
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    # The pinned package's bin/cmux launches the GUI instead of the socket CLI.
    # Keep this workaround local to interactive shells and tied to the package.
    home.file.".config/shell/cmux.sh".text = ''
      cmux() {
        command "${pkgs.cmux}/Applications/cmux.app/Contents/Resources/bin/cmux" "$@"
      }
    '';
    xdg.configFile."ghostty/config".source = ../config/ghostty/config;
    xdg.configFile."cmux/cmux.json".text = builtins.toJSON {
      schemaVersion = 1;
      app = {
        appearance = "dark";
        confirmQuit = "always";
        workspaceInheritWorkingDirectory = true;
        newWorkspacePlacement = "afterCurrent";
        reorderOnNotification = false;
        sendAnonymousTelemetry = false;
        preferredEditor = "code";
        openSupportedFilesInCmux = false;
      };
      automation = {
        claudeCodeIntegration = false;
        suppressSubagentNotifications = true;
      };
      browser = {
        openTerminalLinksInCmuxBrowser = false;
        interceptTerminalOpenCommandInCmuxBrowser = false;
      };
      sidebar = {
        showBranchDirectory = true;
        showNotificationMessage = true;
        showProgress = true;
        openPortLinksInCmuxBrowser = false;
        openPullRequestLinksInCmuxBrowser = false;
      };
      notifications = {
        dockBadge = true;
        unreadPaneRing = true;
        paneFlash = false;
      };
      shortcuts.bindings = {
        splitRight = "cmd+d";
        splitDown = "cmd+shift+d";
        toggleSplitZoom = "cmd+shift+return";
        showNotifications = "cmd+i";
        jumpToUnread = "cmd+shift+u";
      };
    };
  };
}
