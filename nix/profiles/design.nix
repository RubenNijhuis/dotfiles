{ lib, pkgs, ... }:

{
  # The GUI applications build through Nix on Linux. Current Apple Silicon
  # Nix packages do not support them, so the macOS profile uses its documented
  # Homebrew exception until upstream support changes.
  home.packages =
    (with pkgs; [
      imagemagick
      oxipng
      pngquant
      svgcleaner
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs;
      [
        krita
        rawtherapee
      ]
    );
}
