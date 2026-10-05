{ pkgs, ... }:

{
  # Portable desktop applications. Hosts opt in explicitly so WSL remains a
  # lean command-line environment.
  home.packages = with pkgs; [
    obsidian
    signal-desktop
    thunderbird
    vscode
  ];
}
