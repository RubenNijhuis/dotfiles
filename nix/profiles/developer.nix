{ pkgs, ... }:

{
  # Deliberately opt-in development layer. Keep language ecosystems per
  # project; this is only the portable tooling used to maintain Nix and
  # JavaScript projects across macOS, Linux, and WSL.
  home.packages = with pkgs; [
    nixfmt
    statix
    deadnix
    nil
    nixd
    nodejs_24
    pnpm
  ];
}
