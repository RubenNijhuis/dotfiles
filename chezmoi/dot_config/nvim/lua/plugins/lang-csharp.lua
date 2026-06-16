return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "omnisharp",
        "csharpier",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
      },
    },
  },
}
