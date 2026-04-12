local lnum_cache = -1
local chars_to_scroll = 50

local function text_area_width()
    local width = vim.api.nvim_win_get_width(0)
    if vim.wo.number or vim.wo.relativenumber then
        local lines = vim.api.nvim_buf_line_count(0)
        width = width - (#tostring(lines) + 1)
    end
    local sc = vim.wo.signcolumn
    if sc == 'yes' or sc == 'auto' then
        width = width - 2
    end
    local fc = tonumber(vim.wo.foldcolumn) or 0
    if fc > 0 then width = width - fc end
    return width
end

local function update()
    if vim.wo.wrap then return end
    local lnum = vim.fn.line('.')
    if lnum == lnum_cache then return end
    lnum_cache = lnum
    local long = vim.fn.strdisplaywidth(vim.api.nvim_get_current_line()) > text_area_width()
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
