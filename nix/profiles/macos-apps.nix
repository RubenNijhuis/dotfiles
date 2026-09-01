{ pkgs, ... }:

{
  # These applications are intentionally macOS-only. Their configuration and
  # account state remain app-managed, while Nix owns the installation.
  home.packages = with pkgs; [
    orbstack
    raycast
  ];
}
