{ pkgs, ... }:

{
  # Opt in only for an active Rust project.
  home.packages = with pkgs; [ rustup ];
}
