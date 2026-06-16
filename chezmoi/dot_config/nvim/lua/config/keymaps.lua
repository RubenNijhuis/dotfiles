-- Custom keymaps (LazyVim provides many defaults — these are additions)
local map = vim.keymap.set

-- Save with Ctrl+S (VS Code muscle memory)
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Escape with jk (fast exit from insert mode)
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Clear search highlighting
map("n", "<leader>/", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- VS Code Cheatsheet (LazyVim defaults):
-- <Space>ff  → Find files       (Cmd+P)
-- <Space>fg  → Live grep        (Cmd+Shift+F)
-- <Space>e   → File explorer    (Sidebar)
-- <Space>gg  → LazyGit          (Git UI)
-- <Space>xx  → Diagnostics      (Problems panel)
-- <Space>ca  → Code actions     (Cmd+.)
-- gd         → Go to definition
-- K          → Hover docs
-- <Space>cc  → Copilot Chat
