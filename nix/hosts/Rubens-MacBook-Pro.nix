{ pkgs, username, ... }:

{
  imports = [ ../darwin/defaults.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.package = pkgs.lix;

  users.users.${username}.home = "/Users/${username}";
  system.primaryUser = username;

  environment.systemPackages = with pkgs; [ git ];

  # Native applications discover these through /Library/Fonts/Nix Fonts.
  # They match the shared Linux and WSL baseline declared in common.nix.
  fonts.packages = with pkgs; [
    open-sans
    nerd-fonts.fira-code
  ];

  # System-level packages stay minimal. Home Manager owns supported desktop
  # applications; Homebrew is limited to documented macOS package exceptions.
  system.stateVersion = 6;
}
