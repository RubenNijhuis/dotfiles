{ pkgs, ... }:

{
  imports = [
    ../home/cmux.nix
    ../home/raycast.nix
  ];

  # These applications are intentionally macOS-only. Their configuration and
  # account state remain app-managed, while Nix owns the installation.
  home.packages = with pkgs; [
    cmux
    orbstack
    raycast
  ];
}
