return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
        json = { "biome", "prettier", stop_after_first = true },
        jsonc = { "biome", "prettier", stop_after_first = true },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      },
      formatters = {
        biome = {
          -- Use project-local biome if available, fall back to global
          prepend_args = { "--write" },
        },
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
      },
    },
  },
  -- Ensure formatters are installed via Mason
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "biome",
        "prettier",
        "shfmt",
      },
    },
  },
}
