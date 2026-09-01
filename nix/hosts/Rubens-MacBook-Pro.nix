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

  # Kept intentionally small for the first switch. Homebrew continues to own
  # GUI apps and macOS-specific software while Nix takes over CLI tools.
  system.stateVersion = 6;
}
