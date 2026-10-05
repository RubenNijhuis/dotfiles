-- Prefer Nix-owned tools; Mason remains a fallback for unmigrated languages.
local function nix_tool(command)
  return vim.fn.resolve(vim.fn.exepath(command)):match("^/nix/store/") ~= nil
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- Do not let old Mason binaries shadow Nix or project devShell tools.
      opts.PATH = "append"
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return not nix_tool(tool)
      end, opts.ensure_installed or {})
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      for server, command in pairs({ bashls = "bash-language-server", lua_ls = "lua-language-server" }) do
        if nix_tool(command) then
          opts.servers[server] = vim.tbl_deep_extend("force", opts.servers[server] or {}, { mason = false })
        end
      end
    end,
  },
}
