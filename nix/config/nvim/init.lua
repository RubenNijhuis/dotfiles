-- Home Manager substitutes this public dependency during the Nix build.
-- Never clone a mutable plugin manager at editor startup.
local lazypath = "@lazy_nvim@"
assert(vim.uv.fs_stat(lazypath), "Nix lazy.nvim is missing; rebuild the editor configuration")
vim.opt.rtp:prepend(lazypath)

-- Set leader key before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("config.lazy")
