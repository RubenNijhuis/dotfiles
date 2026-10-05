{ pkgs, ... }:

let
  # The pinned Zoom build strips its signed binaries, breaking its signature.
  # Preserve the signed payload; its CLI wrapper still lives outside the app.
  zoom = pkgs.zoom-us.overrideAttrs {
    dontStrip = true;
    dontPatchShebangs = true;
  };
in
{
  imports = [
    ../home/cmux.nix
    ../home/raycast.nix
  ];

  # These applications are intentionally macOS-only. Their configuration and
  # account state remain app-managed, while Nix owns the installation.
  home.packages = [
    pkgs.cmux
    pkgs.orbstack
    pkgs.raycast
    # Already-installed specialist apps. Keep these out of the portable base;
    # accounts, CrossOver bottles/licenses, and Zoom helpers stay app-owned.
    pkgs.crossover
    zoom
  ];
}
