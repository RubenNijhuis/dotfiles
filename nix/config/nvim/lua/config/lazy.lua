-- Nix-owned LazyVim loader.
local lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"

-- The configuration directory is Nix-owned and therefore immutable. Seed a
-- writable runtime lockfile once, then let explicit Lazy updates modify only
-- local editor state rather than the declarative configuration.
if vim.fn.filereadable(lockfile) == 0 then
  local source_lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  if vim.fn.filereadable(source_lockfile) == 1 then
    vim.fn.mkdir(vim.fn.fnamemodify(lockfile, ":h"), "p")
    vim.fn.writefile(vim.fn.readfile(source_lockfile), lockfile)
  end
end

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Import LazyVim extras (configured in lazyvim.json)
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.svelte" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.ruby" },
    { import = "lazyvim.plugins.extras.lang.zig" },
    { import = "lazyvim.plugins.extras.lang.toml" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "lazyvim.plugins.extras.ai.copilot" },
    { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
    -- Import custom plugin specs
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  -- Keep startup deterministic while this plugin graph remains outside Nix.
  -- Plugin changes are deliberate manual `:Lazy sync` actions until the editor
  -- migration pins them declaratively.
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
