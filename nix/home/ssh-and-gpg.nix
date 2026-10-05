{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  # Pinned Nix Mac pinentry is 1.1.1.1, older than installed 1.3.1.1.
  # Keep that documented exception rather than silently downgrading it.
  pinentryPath =
    if isDarwin then
      "${if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local"}/bin/pinentry-mac"
    else
      "${pkgs.pinentry-curses}/bin/pinentry-curses";
in
{
  home.packages = [
    # Portable recovery-file encryption; keys and passphrases stay outside Nix.
    pkgs.age
    pkgs.gnupg
  ]
  ++ lib.optionals (!isDarwin) [
    pkgs.openssh
    pkgs.pinentry-curses
  ];

  # New homes need private parent directories; mkdir leaves existing ones alone.
  home.activation.privateConfigDirs =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        run mkdir -m700 -p ${lib.escapeShellArg "${config.home.homeDirectory}/.ssh"} ${lib.escapeShellArg "${config.home.homeDirectory}/.gnupg"}
      '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # macOS keeps its system SSH client and Keychain integration.
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/config.d/common.conf"
      "~/.ssh/config.d/personal.conf"
      "~/.ssh/config.d/work.conf"
      "~/.ssh/config.d/local.conf"
    ];
  };

  home.file = {
    ".ssh/config.d/common.conf".text =
      lib.replaceStrings
        [ "    UseKeychain yes\n" ]
        [ (lib.optionalString isDarwin "    IgnoreUnknown UseKeychain\n    UseKeychain yes\n") ]
        (builtins.readFile ../config/ssh/common.conf);
    ".ssh/config.d/personal.conf".source = ../config/ssh/personal.conf;
    ".gnupg/gpg.conf".source = ../config/gpg/gpg.conf;
    ".gnupg/gpg-agent.conf".text = ''
      default-cache-ttl 600
      max-cache-ttl 7200
      pinentry-program ${pinentryPath}
    '';
  };
  # No new launchd/systemd service, key import, agent restart, or keyring link.
}
