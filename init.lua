vim.cmd("set number")
vim.cmd("set relativenumber")
vim.cmd("set mouse=a")
vim.cmd("set clipboard=unnamed")
vim.cmd("set nowrap")
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.shortmess:append("c")
vim.opt.previewheight = 10
vim.opt.laststatus = 3
vim.opt.scrolloff = 10
vim.opt.signcolumn = "yes"

vim.opt.ignorecase = true
vim.opt.smartcase = true

-- vim.opt.spell = true
-- vim.opt.spelllang = "en_us"
vim.opt.spelloptions = "camel"

-- Indent
vim.cmd("set expandtab")    --Use spaces instead of tabs
vim.cmd("set tabstop=4")    -- 1 tab = 4 spaces
vim.cmd("set shiftwidth=4")
vim.cmd("set softtabstop=4")
vim.cmd("set autoindent")   -- Enable auto-indentation
vim.cmd("set smartindent")

-- Remap c (change) to c register
vim.keymap.set("n", "c", '"cc')
vim.keymap.set("x", "c", '"cc')

require("config.lazy")
require("config.keymaps")
require("commands.commands")
