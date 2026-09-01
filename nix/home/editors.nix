{ ... }:

{
  programs.neovim.enable = true;

  # The existing LazyVim configuration is owned as one immutable directory.
  # Lazy.nvim/Mason data remains local for now; pinning that plugin graph is a
  # separate editor migration, including an explicit Copilot replacement plan.
  home.file.".config/nvim".source = ../config/nvim;
}
