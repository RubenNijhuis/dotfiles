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
}
