return {
  -- Ensure shell tooling is installed via Mason
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "bash-language-server",
        "shfmt",
        "shellcheck",
      },
    },
  },

  -- Lint shell scripts with shellcheck
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },
}
