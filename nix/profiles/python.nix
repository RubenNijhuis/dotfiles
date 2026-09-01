{ pkgs, ... }:

{
  # Opt in only for an active Python project.
  home.packages = with pkgs; [ uv ];
}
