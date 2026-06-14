local M = {}

local state = {}

function M.rerender()
    if state.buf and vim.api.nvim_buf_is_valid(state.buf)
    and state.win and vim.api.nvim_win_is_valid(state.win) then
        require("modules.dashboard.layout").render(state.buf, state.win)
    end
end

function M.open()
    -- Wipe the initial [No Name] buffer so it doesn't linger in the buffer list.
    local prev_buf = vim.api.nvim_get_current_buf()
    local prev_is_blank = vim.api.nvim_buf_get_name(prev_buf) == ""
                       and not vim.bo[prev_buf].modified
                       and vim.bo[prev_buf].buftype == ""

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buftype   = "nofile"
    vim.bo[buf].swapfile  = false

    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = "dashboard"

    if prev_is_blank and vim.api.nvim_buf_is_valid(prev_buf) then
        pcall(vim.api.nvim_buf_delete, prev_buf, { force = true })
    end

    local win = vim.api.nvim_get_current_win()
    state.buf = buf
    state.win = win

    local wo = vim.wo[win]
    local saved = {
        number         = wo.number,
        relativenumber = wo.relativenumber,
        cursorline     = wo.cursorline,
        signcolumn     = wo.signcolumn,
        foldcolumn     = wo.foldcolumn,
        wrap           = wo.wrap,
    }

    require("modules.dashboard.layout").render(buf, win)
    require("modules.dashboard.joke").fetch_async(function()
        M.rerender()
    end)

    -- Restore window options on leave. vim.schedule runs after all BufEnter/FileType
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer   = buf,
        callback = function()
            if not vim.api.nvim_win_is_valid(win) then return end
            vim.schedule(function()
                if not vim.api.nvim_win_is_valid(win) then return end
                -- If the dashboard buffer is still in its window (e.g. focus moved to a float)
                if vim.api.nvim_win_get_buf(win) == buf then return end
                if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then return end
                local w = vim.wo[win]
                w.number         = saved.number
                w.relativenumber = saved.relativenumber
                w.cursorline     = saved.cursorline
                w.signcolumn     = saved.signcolumn
                w.foldcolumn     = saved.foldcolumn
                w.wrap           = saved.wrap
                w.statusline     = ""
            end)
        end,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
        buffer   = buf,
        callback = function()
            if vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= "" then return end
            if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
                require("modules.dashboard.layout").render(buf, win)
            end
        end,
    })

    vim.api.nvim_create_autocmd("VimResized", {
        buffer   = buf,
        callback = function()
            if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
                require("modules.dashboard.layout").render(buf, win)
            end
        end,
    })
end

function M.setup()
    vim.api.nvim_create_autocmd("VimEnter", {
        once     = true,
        callback = function()
            if vim.fn.argc() == 0 then M.open() end
        end,
    })
end

return M
