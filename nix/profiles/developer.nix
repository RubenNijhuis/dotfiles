{ pkgs, ... }:

{
  # Deliberately opt-in development layer. Keep language ecosystems per
  # project; this is only the portable tooling used to maintain Nix and
  # JavaScript projects across macOS, Linux, and WSL.
  home.packages = with pkgs; [
    biome
    deadnix
    dust
    gh
    gum
    hyperfine
    jujutsu
    nil
    nixd
    nixfmt
    nodejs_24
    parallel
    pnpm
    prettier
    shellharden
    statix
  ];
}
