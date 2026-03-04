-- Hide highlights on search by *, /
vim.keymap.set("n","<leader>-",function () MiniFiles.open() end,{desc = "Open file explorer."})
vim.keymap.set("n","<leader>-",function () MiniFiles.open() end,{desc = "Open file explorer."})
vim.keymap.set("n", "<Esc>", "<cmd>noh<CR>")

local wk = require("which-key")
wk.add({
    { "<leader>c",  group = "Code" },
    { "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, desc = "Format buffer" },
    { "K",          vim.lsp.buf.hover,                                   desc = "Show hover" },
    { "<leader>cg", function() vim.lsp.buf.definition() end,             desc = "LSP Goto Definition"},
    { "<leader>cr", function() vim.lsp.buf.references() end,             desc = "LSP Goto Reference" },
    -- { "<Leader>ca", vim.lsp.buf.code_action,                             desc = "Code actions", mode = "v" },
    -- { "<leader>ca", vim.lsp.buf.code_action,                             desc = "Code actions" },
    { "<F2>",       vim.lsp.buf.rename,                                  desc = "Rename symbol" }
})

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
-- vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope keymaps' })
vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = 'Telescope commands' })
vim.keymap.set("n", "<leader>f/", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy search in buffer" })

vim.keymap.set("n", "<leader>//", function()
  require("telescope.builtin").current_buffer_fuzzy_find()
end, { desc = "Fuzzy search in buffer" })

vim.keymap.set({ "n", "x" }, "<leader>ca", function()
	require("tiny-code-action").code_action()
end, { noremap = true, silent = true })


-- jump to warning
vim.keymap.set("n", "<leader>dw", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN })
end, { desc = "Jump to next Warning" })

vim.keymap.set("n", "<leader>dW", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN })
end, { desc = "Jump prev Warning" })

-- jump to error
vim.keymap.set("n", "<leader>de", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR})
end, { desc = "Jump next Error" })

vim.keymap.set("n", "<leader>dE", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Jump to prev Error" })

vim.keymap.set("n", "<leader>w", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap
  vim.wo.breakindent = vim.wo.wrap
end, { desc = "Toggle soft wrap mode" })

-- Session Management Keymaps
local sessions = require('mini.sessions')
--vim.keymap.set('n', '<Leader>sl', function() sessions.select() end, { desc = 'Sessions: List' }) -- In telescope/session
vim.keymap.set('n', '<Leader>sw', function() 
    local name = vim.fn.input('Session name: ')
    if name ~= "" then sessions.write(name) end
end, { desc = 'Sessions: Write' })

vim.keymap.set('n', '<Leader>sd', function() sessions.select('delete') end, { desc = 'Sessions: Delete' })
vim.keymap.set('n', '<Leader>sr', function() sessions.read() end, { desc = 'Sessions: Read' })

vim.keymap.set('n', '<Leader>nh', function() Snacks.notifier.show_history() end, { desc = 'Notifications history' })

vim.keymap.set("n","<leader>t",function () require('alternate-toggler').toggleAlternate() end,{desc = "Invert boolean value."})

vim.keymap.set("n","<leader>-",function () MiniFiles.open() end,{desc = "Open file explorer."})
vim.keymap.set("n","<leader>gv",function () MiniDiff.toggle_overlay() end,{desc = "Git changes view toggle(MiniDiff)"})

vim.keymap.set("n","<leader>pc",function () require("minty.huefy").open() end,{desc = "Open color picker"})
vim.keymap.set("n","<leader>ps",function () require("minty.shades").open() end,{desc = "Open color picker, shade"})

vim.keymap.set("n","<RightMouse>",function ()
    require('menu.utils').delete_old_menus()
    vim.cmd.exec '"normal! \\<RightMouse>"'
    -- require("plenary.reload").reload_module "menus"
    -- require("plenary.reload").reload_module "menu"
    require("menu").open("default")
end,{desc = "Menu"})
-- <F16> is menu in win terminal
-- { 
--     "command": { "action": "sendInput", "input": "\u001b[29~" }, 
--     "keys": "menu" 
-- }
vim.keymap.set("n","<F16>",function ()require('menu.utils').delete_old_menus() require("menu").open("default") end,{desc = "Menu"})
