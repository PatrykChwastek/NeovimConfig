local function create_floating_window(opts)
    opts = opts or {}
    local width = opts.width or math.floor(vim.o.columns * 0.8)
    local height = opts.height or math.floor(vim.o.lines * 0.8)

    -- Calculate the position to center the window
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Create a buffer
    local buf = nil
    if vim.api.nvim_buf_is_valid(opts.buf) then
        buf = opts.buf
    else
        buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
    end

    local win_config = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
    }

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, win_config)

    return { buf = buf, win = win }
end

local termState = { buf = -1, win = -1 }

local toggle_terminal = function()
    if not vim.api.nvim_win_is_valid(termState.win) then
        termState = create_floating_window { buf = termState.buf }
        if vim.bo[termState.buf].buftype ~= "terminal" then
            vim.cmd.terminal()
        end
        vim.cmd("startinsert")
    else
        vim.api.nvim_win_hide(termState.win)
    end
end

local scratchState = { buf = -1, win = -1 }

local toggle_scratch = function()
    if not vim.api.nvim_win_is_valid(scratchState.win) then
        scratchState = create_floating_window { buf = scratchState.buf }

        local win = scratchState.win
        vim.wo[win].number = true         -- Show line numbers
        vim.wo[win].relativenumber = true -- Show relative line numbers
        vim.wo[win].signcolumn = "yes"    -- Leave space for git signs/diagnostics
        vim.wo[win].cursorline = true     -- Highlight the current line
    else
        vim.api.nvim_win_hide(scratchState.win)
    end
end

vim.api.nvim_create_user_command("Floaterminal", toggle_terminal, {})
vim.api.nvim_create_user_command("Scratch", toggle_scratch, {})
