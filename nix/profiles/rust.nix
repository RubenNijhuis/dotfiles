{ pkgs, ... }:

{
  # Opt in only for an active Rust project. Keep the toolchain pinned by the
  # flake rather than introducing mutable rustup state on every machine.
  home.packages = with pkgs; [
    cargo
    clippy
    rustc
    rustfmt
  ];
}
