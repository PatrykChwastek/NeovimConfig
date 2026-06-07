vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamed"
vim.opt.wrap = false
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.shortmess:append("c")
vim.opt.previewheight = 10
vim.opt.laststatus = 3
vim.opt.scrolloff = 10
-- vim.opt.sidescrolloff = 60
vim.opt.signcolumn = "yes"

vim.opt.ignorecase = true
vim.opt.smartcase = true

-- vim.opt.spell = true
-- vim.opt.spelllang = "en_us"
vim.opt.spelloptions = "camel"

-- Indent
vim.opt.expandtab = true      -- Use spaces instead of tabs
vim.opt.tabstop = 4           -- 1 tab = 4 spaces
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true     -- Enable auto-indentation
vim.opt.smartindent = true

-- set terminal base on os
if vim.fn.has("win32") == 1 then
  if vim.fn.executable("pwsh") == 1 then
    vim.opt.shell = "pwsh"
  else
    vim.opt.shell = "powershell"
  end
end

vim.filetype.add({ extension = {dat = "dat"}})

-- Remap c (change) to c register
vim.keymap.set("n", "c", '"cc')
vim.keymap.set("x", "c", '"cc')

require("config.lazy")
require("config.keymaps")
require("config.neovide")
require("commands.commands")
require("modules.modules")
