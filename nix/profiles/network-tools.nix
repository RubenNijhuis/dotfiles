{ lib, pkgs, ... }:

let
  # Preserve the already-installed agent version until the upstream pin catches
  # up. This override is Apple-Silicon-only; other hosts use their native pin.
  version = "3.39.11";
  ngrok =
    if
      pkgs.stdenv.hostPlatform.system != "aarch64-darwin" || lib.versionAtLeast pkgs.ngrok.version version
    then
      pkgs.ngrok
    else
      pkgs.ngrok.overrideAttrs (old: {
        inherit version;
        src = pkgs.fetchurl {
          url = "https://bin.ngrok.com/a/dy27whJwwmb/ngrok-v3-${version}-darwin-arm64.zip";
          hash = "sha256-kySmVS104l1b39vtxLMkIslvBE/aN4d0mK2O8Qvd9/c=";
        };
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.unzip ];
        unpackPhase = ''
          runHook preUnpack
          unzip -q "$src"
          runHook postUnpack
        '';
      });
in
{
  # Opt-in tools retained from this Mac, not a global developer requirement.
  # Install no service and never import VPN, tunnel, or Signal account state.
  home.packages = [
    pkgs.signal-cli
    pkgs.tailscale
    ngrok
  ];
}
