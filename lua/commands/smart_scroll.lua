local lnum_cache = -1
local chars_to_scroll = 50

local function update()
    if vim.wo.wrap then return end
    local lnum = vim.fn.line('.')
    if lnum == lnum_cache then return end
    lnum_cache = lnum
    local long = vim.fn.strdisplaywidth(vim.api.nvim_get_current_line()) > vim.api.nvim_win_get_width(0)
    vim.wo.sidescrolloff = long and chars_to_scroll or 0
end

vim.api.nvim_create_autocmd("CursorMoved", { callback = update })

-- Reset cache on buffer/window switch so the new line is evaluated immediately.
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    callback = function()
        lnum_cache = -1
        update()
    end,
})
