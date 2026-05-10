if vim.g.neovide then

    vim.keymap.set("", "<M-CR>", function()
        vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
    end, { desc = "Toggle Neovide fullscreen" })

    --Shift Insert paste
    vim.keymap.set({ "n", "i", "c", "t" }, "<S-Insert>", '<C-R>+', {
        remap = false,
    })


    -- Terminal mode
    local terminal_ui_group =
    vim.api.nvim_create_augroup("TerminalUI", { clear = true })

    local function enable_terminal_ui()
        -- local window options
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"

        -- global UI options
        vim.opt.laststatus = 0
        vim.opt.cmdheight = 0
        vim.opt.showmode = false

        vim.cmd("redraw")
    end

    local function disable_terminal_ui()
        -- restore your normal editor UI here
        vim.opt.laststatus = 3
        vim.opt.cmdheight = 1
        vim.opt.showmode = true

        vim.cmd("redraw")
    end

    local function update_ui()
        local is_terminal = vim.bo.buftype == "terminal"

        if is_terminal then
            enable_terminal_ui()
        else
            disable_terminal_ui()
        end
    end

    -- Auto apply terminal UI

    vim.api.nvim_create_autocmd("TermOpen", {
        group = terminal_ui_group,
        callback = function()
            enable_terminal_ui()

            vim.cmd("startinsert")
        end,
    })

    vim.api.nvim_create_autocmd({
        "BufEnter",
        "WinEnter",
        "TermClose",
    }, {
        group = terminal_ui_group,
        callback = function()
            update_ui()
        end,
    })

    -- Start Neovide directly in terminal
    vim.api.nvim_create_autocmd("VimEnter", {
        group = terminal_ui_group,
        callback = function()
            vim.cmd("enew")
            vim.cmd("terminal")

            enable_terminal_ui()

            vim.cmd("startinsert")
        end,
    })
end
