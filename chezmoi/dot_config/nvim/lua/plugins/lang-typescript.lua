return {
  -- Use Biome as linter for JS/TS files
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "biomejs" },
        javascriptreact = { "biomejs" },
        typescript = { "biomejs" },
        typescriptreact = { "biomejs" },
      },
    },
  },
}
