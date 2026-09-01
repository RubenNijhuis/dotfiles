{ pkgs, ... }:

{
  # Tools only: device pairing, folder selection, versioning, and backup
  # destinations remain explicit personal choices outside the Nix store.
  home.packages = with pkgs; [
    restic
    syncthing
  ];
}
