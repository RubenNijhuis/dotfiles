{ lib, pkgs, ... }:

{
  # Gaming is Linux-desktop-only. GPU drivers, Steam hardware support, and
  # game launchers belong in the Linux host module, never in a laptop base.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
    with pkgs;
    [
      heroic
      mangohud
      prismlauncher
    ]
  );
}
