{ username, ... }:

{
  # Declarative macOS preferences migrated from the ChezMoi defaults script.
  # That script now owns only Dock item placement and Library visibility.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      AppleShowScrollBars = "Automatic";
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      "com.apple.mouse.tapBehavior" = 1;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
    };

    dock = {
      autohide = true;
      autohide-delay = 0.0;
      show-recents = false;
      tilesize = 48;
      minimize-to-application = true;
      orientation = "left";
      mineffect = "scale";
      mru-spaces = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };

    screencapture = {
      location = "/Users/${username}/Files/00 Inbox/Screenshots";
      target = "file";
      type = "png";
      disable-shadow = true;
    };

    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleAccentColor = -2;
        AppleAquaColorVariant = 1;
        AppleHighlightColor = "0.478431 0.635294 0.968627 Other";
        ContextMenuGesture = 1;
        "com.apple.swipescrolldirection" = true;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.finder" = {
        NewWindowTarget = "PfHm";
        NewWindowTargetPath = "file:///Users/${username}/";
      };
      "com.microsoft.VSCode".ApplePressAndHoldEnabled = false;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
