{ pkgs, ... }:

{
  # Opt in only for an active Go project.
  home.packages = with pkgs; [ go ];
}
