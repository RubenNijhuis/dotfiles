{ pkgs, ... }:

{
  # Portable desktop applications. Hosts opt in explicitly so WSL remains a
  # lean command-line environment.
  home.packages = with pkgs; [
    cmux
    obsidian
    signal-desktop
    thunderbird
    vscode
  ];
}
