-- Fresh-profile smoke test: no personal documents, credentials, or downloads.
local built = assert(arg[1], "built configuration required")
local repo = assert(vim.env.DOTFILES_TEST_ROOT)
local function run()
  local blocked = {}
  local spawn = vim.uv.spawn
  vim.uv.spawn = function(command, opts, callback)
    local name = vim.fs.basename(command)
    if name == "git" or name == "lua-language-server" then
      assert(not vim.tbl_contains(opts.args or {}, "fetch") and not vim.tbl_contains(opts.args or {}, "clone"))
      return spawn(command, opts, callback)
    end
    blocked[#blocked + 1] = name
    error("Unexpected subprocess in offline smoke test: " .. name)
  end
  vim.opt.rtp:prepend(built)
  vim.go.loadplugins = true
  local bootstrap =
    assert(table.concat(vim.fn.readfile(built .. "/init.lua"), "\n"):match('local lazypath = "([^"]+)"'))
  vim.opt.rtp:prepend(bootstrap)
  local lazy = require("lazy")
  local setup = lazy.setup
  lazy.setup = function(opts)
    -- Do not start AI clients or touch real credentials in a test profile.
    opts.spec[#opts.spec + 1] = { "zbirenbaum/copilot.lua", enabled = false }
    opts.spec[#opts.spec + 1] = { "CopilotC-Nvim/CopilotChat.nvim", enabled = false }
    opts.spec[#opts.spec + 1] = {
      "saghen/blink.cmp",
      opts = function(_, cmp)
        cmp.sources.default = vim.tbl_filter(function(source)
          return source ~= "copilot"
        end, cmp.sources.default)
        cmp.sources.providers.copilot = nil
      end,
    }
    setup(opts)
  end
  dofile(built .. "/init.lua")
  vim.cmd.edit(repo .. "/tests/neovim.lua")
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
  local attached = vim.wait(5000, function()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if client.initialized then
        return true
      end
    end
    return false
  end)
  local config = require("lazy.core.config")
  assert(#config.to_clean == 0, "fresh profile must not require cleanup")
  for name, plugin in pairs(config.plugins) do
    assert(plugin._.installed and plugin.dir:match("^/nix/store/"), "not Nix-owned: " .. name)
  end
  assert(#blocked == 0, "runtime downloads/subprocesses were requested")
  local ts = require("nvim-treesitter")
  local languages = ts.get_installed("parsers")
  assert(vim.tbl_contains(languages, "lua"))
  for _, lang in ipairs(languages) do
    assert(vim.treesitter.language.add(lang), "parser failed to load: " .. lang)
  end
  for _, lang in ipairs({ "lua", "bash", "python", "typescript", "markdown" }) do
    assert(vim.treesitter.language.add(lang), "parser missing: " .. lang)
    assert(vim.treesitter.query.get(lang, "highlights"), "queries missing: " .. lang)
  end
  assert(type(require("blink.cmp").setup) == "function")
  vim.api.nvim_exec_autocmds("InsertEnter", { modeline = false })
  vim.wait(2000, function()
    return require("blink.cmp.fuzzy").implementation_type == "rust"
  end)
  assert(require("blink.cmp.fuzzy").implementation_type == "rust", "Nix native completion library not loaded")
  assert(attached, "Lua language server did not initialize and attach")
  assert(vim.v.errmsg == "", vim.v.errmsg)
end
local ok, err = xpcall(run, debug.traceback)
vim.lsp.stop_client(vim.lsp.get_clients(), true)
vim.wait(500, function()
  return false
end) -- let only this test's server exit
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
io.stdout:write("PASS: fresh-profile Nix plugins, parsers, native completion, and Lua LSP (AI clients excluded)\n")
vim.cmd("qa!")
