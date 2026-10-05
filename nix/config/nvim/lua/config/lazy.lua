-- Nix-owned LazyVim loader.
local lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
local registry = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath("config") .. "/nix-plugins.json"), "\n"))

local spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
  -- LazyVim imports extras from lazyvim.json; do not duplicate that list here.
  -- Import custom plugin specs
  { import = "plugins" },
}
-- Preserve upstream plugin conditions while replacing their runtime downloads.
for name, path in pairs(registry.plugins) do
  spec[#spec + 1] = { name = name, dir = path, optional = true, pin = true, build = false }
end
spec[#spec + 1] = {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.install_dir = registry.parsers
    opts.ensure_installed = {} -- compiled parsers/queries come from Nix
  end,
}
spec[#spec + 1] = {
  "saghen/blink.cmp",
  opts = { fuzzy = { prebuilt_binaries = { download = false, force_version = "v" .. registry.blinkVersion } } },
}
-- Keep Mason available for deliberate installs, not global SDK bootstrapping.
spec[#spec + 1] = {
  "mason-org/mason.nvim",
  opts = function(_, opts)
    opts.ensure_installed = {}
  end,
  config = function(_, opts)
    require("mason").setup(opts)
  end,
}
spec[#spec + 1] = {
  "mason-org/mason-lspconfig.nvim",
  enabled = false, -- its registry mapping refresh otherwise downloads at startup
}
spec[#spec + 1] = {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    for _, server in pairs(opts.servers) do
      if type(server) == "table" then
        server.mason = false
      end
    end
  end,
}

require("lazy").setup({
  root = vim.fn.stdpath("data") .. "/nix-loader", -- keep legacy checkouts out of Lazy's cleanup candidates
  spec = spec,
  dev = {
    patterns = { "." },
    fallback = false,
    path = function(plugin)
      -- Upstream optional specs are parsed before Lazy drops unused plugins.
      return registry.plugins[plugin.name] or registry.plugins["lazy.nvim"] .. "/undeclared-" .. plugin.name
    end,
  },
  pkg = { enabled = false },
  rocks = { enabled = false },
  defaults = {
    lazy = false,
    version = false,
  },
  -- Nix updates the graph; Lazy remains only a runtime loader.
  checker = { enabled = false },
  install = { missing = false },
  lockfile = lockfile,
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

for name in pairs(require("lazy.core.config").plugins) do
  assert(registry.plugins[name], "Plugin is not declared in Nix: " .. name)
end
