{ pkgs, ... }:

{
  # Package defaults only: never declare profiles or accounts here. Replacing
  # profiles.ini would recreate the earlier signed-in/empty-profile split.
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird.override {
      extraPrefs = ''
        defaultPref("font.name.sans-serif.x-western", "Open Sans");
        defaultPref("mail.uidensity", 0);
        defaultPref("privacy.globalprivacycontrol.enabled", true);
      '';
    };
    policies.DisableTelemetry = true;
  };
}
