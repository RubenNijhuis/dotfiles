-- No plugin setup or external downloads: exercise the Nix ownership boundary.
local root = assert(vim.env.DOTFILES_TEST_ROOT)
for _, file in ipairs(vim.fn.glob(root .. "/nix/config/nvim/**/*.lua", false, true)) do
  assert(loadfile(file))
end
local spec = dofile(root .. "/nix/config/nvim/lua/plugins/nix-tools.lua")
local exepath, resolve = vim.fn.exepath, vim.fn.resolve
local owned = {
  shfmt = true,
  stylua = true,
  biome = true,
  prettier = true,
  ["bash-language-server"] = true,
  ["lua-language-server"] = true,
}
vim.fn.exepath = function(command)
  return owned[command] and "/nix/store/test/bin/" .. command or ""
end
vim.fn.resolve = function(path)
  return path
end
local mason = { ensure_installed = { "shfmt", "stylua", "biome", "prettier", "csharpier" } }
spec[1].opts(nil, mason)
assert(mason.PATH == "append")
assert(vim.deep_equal(mason.ensure_installed, { "csharpier" }))
local lsp = { servers = { lua_ls = { settings = { retained = true } }, pyright = {} } }
spec[2].opts(nil, lsp)
assert(lsp.servers.lua_ls.mason == false and lsp.servers.lua_ls.settings.retained)
assert(lsp.servers.bashls.mason == false and lsp.servers.pyright.mason == nil)
owned = {}
local fallback = { servers = { lua_ls = {} } }
spec[2].opts(nil, fallback)
assert(fallback.servers.lua_ls.mason == nil and fallback.servers.bashls == nil)
vim.fn.exepath, vim.fn.resolve = exepath, resolve
-- Optionally verify a built configuration; never execute the full LazyVim graph.
local built = arg[1]
if built and built ~= "" then
  local init = table.concat(vim.fn.readfile(built .. "/init.lua"), "\n")
  assert(not init:find("@lazy_nvim@", 1, true), "bootstrap was not substituted")
  local bootstrap = assert(init:match('local lazypath = "([^"]+)"'))
  assert(bootstrap:match("^/nix/store/") and vim.uv.fs_stat(bootstrap))
  vim.opt.rtp:prepend(bootstrap)
  assert(type(require("lazy").setup) == "function")
  -- Resolve the existing graph read-only, with all plugin execution disabled.
  -- This verifies the real option merge without Mason installs or parser builds.
  if arg[2] and arg[2] ~= "" then
    vim.opt.rtp:prepend(built)
    vim.opt.rtp:append(arg[2] .. "/LazyVim")
    local lazy = require("lazy")
    lazy.setup = function(opts)
      opts.root = arg[2]
      opts.defaults.cond = false
      opts.spec[#opts.spec + 1] = { "folke/lazy.nvim", cond = true }
      opts.pkg = { enabled = false }
      opts.rocks = { enabled = false }
      opts.readme = { enabled = false }
      opts.performance.rtp.reset = false
      require("lazy.core.config").setup(opts)
      require("lazy.core.plugin").load()
    end
    dofile(built .. "/init.lua")
    local config = require("lazy.core.config")
    assert(config.plugins["lazy.nvim"].dir == bootstrap and config.plugins["lazy.nvim"]._.is_local)
    local plugins = config.spec.disabled
    local opts = require("lazy.core.plugin").values(assert(plugins["mason.nvim"]), "opts", false)
    assert(opts.PATH == "append")
    for _, tool in ipairs(opts.ensure_installed) do
      assert(not vim.fn.resolve(vim.fn.exepath(tool)):match("^/nix/store/"), tool .. " still requested by Mason")
    end
    local servers = require("lazy.core.plugin").values(assert(plugins["nvim-lspconfig"]), "opts", false).servers
    assert(servers.bashls.mason == false and servers.lua_ls.mason == false)
    print("PASS: real LazyVim graph option merge (plugin execution disabled)")
  end
end
print("PASS: Neovim Lua, Nix tool ownership, and optional built bootstrap")
