{ pkgs, ... }:

{
  # The only currently evidenced global language environment. Project-specific
  # package managers and dependencies remain inside each project.
  home.packages = with pkgs; [
    nodejs_24
    pnpm
  ];
}
