{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Remove this compatibility override once the pin supplies >= 2.45.3.
  # Never downgrade the CLI used to patch the installed Spotify client.
  version = "2.45.3";
  spicetify =
    if lib.versionAtLeast pkgs.spicetify-cli.version version then
      pkgs.spicetify-cli
    else
      pkgs.spicetify-cli.overrideAttrs (old: {
        inherit version;
        vendorHash = "sha256-1yoFdrSgKB1kWtt7wz/gzNvl+v8v9Z/Ab3Kegb/5Q7M=";
        src = pkgs.fetchzip {
          url = "https://github.com/spicetify/cli/archive/refs/tags/v${version}.tar.gz";
          hash = "sha256-+EsZHr9cJDvSlYnwlmLjv0iT6s6gpMCd3+RKl0pUbFM=";
        };
        postPatch = lib.replaceStrings [ old.version ] [ version ] old.postPatch;
        ldflags = map (lib.replaceStrings [ old.version ] [ version ]) old.ldflags;
      });
in
{
  # Opt-in theming only, not a requirement of core, development, or gaming.
  # Spotify itself, config-xpui.ini, marketplace, and backups stay app-owned.
  # In particular, never patch an immutable /nix/store Spotify installation.
  home.packages = [ spicetify ];
  home.sessionVariables.SPICETIFY_CONFIG = "${config.xdg.configHome}/spicetify";
  home.file = {
    ".config/spicetify/Themes/TokyoNight/color.ini".source = ../config/spicetify/TokyoNight/color.ini;
    ".config/spicetify/Themes/TokyoNight/user.css".source = ../config/spicetify/TokyoNight/user.css;
  };
}
