-- Options ported from old .vimrc + LazyVim defaults
local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 8
-- Search
opt.ignorecase = true
opt.smartcase = true

-- System clipboard
opt.clipboard = "unnamedplus"

-- No backups / swap (git handles versioning)
opt.backup = false
opt.swapfile = false
opt.writebackup = false

-- Encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- Split behavior (match VS Code)
opt.splitbelow = true
opt.splitright = true

-- Undo persistence
opt.undofile = true
