{ pkgs, ... }:

{
  # Deliberately opt-in development layer. Keep language ecosystems per
  # project; this is only the portable tooling used to maintain Nix and
  # JavaScript projects across macOS, Linux, and WSL.
  home.packages = with pkgs; [
    biome
    bash-language-server
    deadnix
    dust
    gh
    gum
    hyperfine
    jujutsu
    lua-language-server
    nil
    nixd
    nixfmt
    nodejs_24
    parallel
    pnpm
    prettier
    shellharden
    shfmt
    statix
    stylua
  ];
}
