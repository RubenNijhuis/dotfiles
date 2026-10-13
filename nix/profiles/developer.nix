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
    lua-language-server
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
  # Experiments and unconfigured Nix language servers are available through
  # `nix develop .#developer-extras`, without installing them on every host.
}
