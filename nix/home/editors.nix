{ pkgs, ... }:

{
  # The binary has no Home Manager-specific settings, so a package declaration
  # avoids overlapping the recursively linked configuration directory below.
  home.packages = [ pkgs.neovim ];

  # The existing LazyVim configuration is owned as one immutable directory.
  # Lazy.nvim/Mason data remains local for now; pinning that plugin graph is a
  # separate editor migration, including an explicit Copilot replacement plan.
  home.file.".config/nvim".source = ../config/nvim;
}
