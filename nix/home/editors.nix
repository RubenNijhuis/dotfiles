{ pkgs, lib, ... }:

let
  pluginRegistry = import ./editor-plugins.nix { inherit pkgs lib; };
in
{
  # The binary has no Home Manager-specific settings, so a package declaration
  # avoids overlapping the recursively linked configuration directory below.
  home.packages = [ pkgs.neovim ];

  # Keep one owner for the whole directory, but substitute the pinned plugin
  # manager at build time. No runtime Git clone or overlapping init.lua link.
  home.file = {
    ".config/nvim".source = pkgs.runCommand "nvim-config" { } ''
      mkdir -p $out
      cp -R ${../config/nvim}/. $out/
      cp ${pluginRegistry} $out/nix-plugins.json
      chmod u+w $out/init.lua
      substituteInPlace $out/init.lua \
        --replace-fail '@lazy_nvim@' '${pkgs.vimPlugins.lazy-nvim}'
    '';

    # Suppress the macOS login banner without carrying ChezMoi ownership.
    ".hushlogin" = {
      text = "";
      force = true;
    };
  };
}
