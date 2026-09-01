{
  lib,
  pkgs,
  username,
  ...
}:

{
  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "26.05";

  # Home Manager already supplies the standard XDG locations that previously
  # lived in .zshenv. Keep the one unique .profile behavior declarative.
  home.sessionPath = [ "$HOME/.cargo/bin" ];

  # Baseline tools without a dedicated Home Manager module. Programs with
  # native modules own their own packages next to their configuration.
  home.packages =
    (with pkgs; [
      eza
      fd
      delta
      jq
      shellcheck
      yq-go
    ])
    # macOS registers these system-wide below. Linux and WSL receive the same
    # deliberately small typography baseline through Home Manager.
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) (
      with pkgs;
      [
        open-sans
        nerd-fonts.fira-code
      ]
    );

  programs.home-manager.enable = true;

  # Project environments are opt-in: a repository needs its own flake and an
  # explicitly approved `.envrc` before anything is loaded into the shell.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
