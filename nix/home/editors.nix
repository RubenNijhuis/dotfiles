{ pkgs, ... }:

{
  # The binary has no Home Manager-specific settings, so a package declaration
  # avoids overlapping the recursively linked configuration directory below.
  home.packages = [ pkgs.neovim ];

  # The existing LazyVim configuration is owned as one immutable directory.
  # Lazy.nvim/Mason data remains local for now; pinning that plugin graph is a
  # separate editor migration, including an explicit Copilot replacement plan.
  home.file = {
    ".config/nvim".source = ../config/nvim;

    # Static editor preferences belong beside the Nix-owned VS Code package.
    # Extensions remain installed through the explicit helper because their
    # marketplace binaries are application-managed state.
    "Library/Application Support/Code/User/settings.json" = {
      source = ../config/vscode/settings.json;
      force = true;
    };
    "Library/Application Support/Code/User/extensions.txt" = {
      source = ../config/vscode/extensions.txt;
      force = true;
    };

    # Suppress the macOS login banner without carrying ChezMoi ownership.
    ".hushlogin" = {
      text = "";
      force = true;
    };
  };
}
