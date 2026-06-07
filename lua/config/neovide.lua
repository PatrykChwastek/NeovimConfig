if vim.g.neovide then
    vim.keymap.set("", "<M-CR>", function()
        vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
    end, { desc = "Toggle Neovide fullscreen" })

    --Shift Insert paste
    vim.keymap.set({ "n", "i", "c"}, "<S-Insert>", '<C-R>+', {
        remap = false,
    })
    vim.keymap.set("t", "<S-Insert>", function() vim.api.nvim_paste(vim.fn.getreg("+"), true, -1) end, { silent = true })

    -- Neovide sends <C-/> but terminal sends <C-_> — normalize for mini.comment
    vim.keymap.set({ "n", "v", "i" }, "<C-/>", "<C-_>", { remap = true })

    vim.g.neovide_text_gamma = 0.4
    vim.g.neovide_text_contrast = 0.4

    vim.g.neovide_normal_opacity = 0.94
    vim.g.neovide_opacity = 0.94

    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_cursor_vfx_particle_lifetime = 0.9
    vim.g.neovide_cursor_vfx_particle_highlight_lifetime = 0.6
    vim.g.neovide_cursor_vfx_particle_density = 0.8

    vim.opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

    local mode_colors = {
        n = "#ff6706", -- normal
        i = "#00a900", -- insert
        v = "#3AA99F", -- visual
        V = "#3AA99F", -- visual line
        ["\22"] = "#3AA99F", -- visual block
        c = "#f0efea", -- command
        R = "#D14D41", -- replace
    }

    local function update_colors()
        local mode = vim.fn.mode()
        local color = mode_colors[mode] or "#f0efea"

        vim.api.nvim_set_hl(0, "Cursor", {
            bg = color,
        })
    end

    vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = update_colors,
    })

    -- set initial color
    update_colors()

    -- Window title: show current directory name
    vim.opt.title = true

    local function update_title()
        local cwd = vim.fn.getcwd()
        local name = vim.fn.fnamemodify(cwd, ":t")
        vim.opt.titlestring = name ~= "" and name or cwd
    end

    vim.api.nvim_create_autocmd("DirChanged", {
        callback = update_title,
    })

    -- Return to terminal instead of closing Neovide when the last editor buffer quits
    local function find_terminal_buf()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf)
               and vim.api.nvim_buf_is_loaded(buf)
               and vim.bo[buf].buftype == "terminal" then
                return buf
            end
        end
    end

    local function go_back_to_terminal()
        if vim.bo.buftype == "terminal" then return false end
        local term_buf = find_terminal_buf()
        if not term_buf then return false end
        local cur = vim.api.nvim_get_current_buf()
        vim.api.nvim_set_current_buf(term_buf)
        pcall(vim.cmd, "bdelete! " .. cur)
        vim.cmd("startinsert")
        return true
    end

    -- ZZ / ZQ: clean remaps, no error flash
    vim.keymap.set("n", "ZZ", function()
        if vim.bo.modified then pcall(vim.cmd, "write") end
        if not go_back_to_terminal() then vim.cmd("q") end
    end)
    vim.keymap.set("n", "ZQ", function()
        if not go_back_to_terminal() then vim.cmd("q!") end
    end)

    -- :q / :wq / :x etc. — cancel quit and redirect (shows a brief error flash)
    vim.api.nvim_create_autocmd("QuitPre", {
        callback = function()
            if #vim.api.nvim_list_wins() > 1 then return end
            if go_back_to_terminal() then error("") end
        end,
    })

    -- Shell detection
    local is_windows = vim.fn.has("win32") == 1
    local shell = vim.o.shell
    local is_pwsh = shell:match("pwsh") ~= nil or shell:match("PowerShell") ~= nil
    local is_fish = shell:match("fish") ~= nil

    local function shell_cmd()
        if is_pwsh then return { "pwsh", "-NoLogo" } end
        if is_fish then return { "fish" } end
        return { shell }
    end

    local function normalize_osc7_path(raw)
        if is_windows then
            return raw:gsub("^/(%a:)", "%1"):gsub("/", "\\")
        end
        return raw
    end

    -- Terminal mode
    local terminal_ui_group =
    vim.api.nvim_create_augroup("TerminalUI", { clear = true })

    local function enable_terminal_ui()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.scrolloff = 3
        vim.opt.cmdheight = 0
        vim.opt.showmode = false
        vim.cmd("redraw")
    end

    local function enable_terminal_normal_ui()
        vim.opt_local.number = true
        vim.opt_local.relativenumber = true
        vim.opt_local.signcolumn = "yes"
        vim.cmd("redraw")
    end

    local function disable_terminal_ui()
        vim.opt.laststatus = 3
        vim.opt.cmdheight = 0
        vim.opt.showmode = false
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
            vim.opt_local.scrolloff = 3
            vim.b.term_cwd = vim.fn.getcwd()
            vim.cmd("startinsert")
        end,
    })

    vim.api.nvim_create_autocmd("TermEnter", {
        group = terminal_ui_group,
        callback = enable_terminal_ui,
    })

    vim.api.nvim_create_autocmd("TermLeave", {
        group = terminal_ui_group,
        callback = enable_terminal_normal_ui,
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

    -- CWD following + custom terminal signals
    vim.api.nvim_create_autocmd("TermRequest", {
        group = terminal_ui_group,
        callback = function(ev)
            local seq = type(ev.data) == "string" and ev.data or vim.v.termrequest

            -- OSC 9999: reset terminal buffer (clear scrollback)
            if seq:match("\x1b%]9999;clear") then
                local cwd = vim.b.term_cwd or vim.fn.getcwd()
                local old_buf = vim.api.nvim_get_current_buf()
                vim.schedule(function()
                    vim.cmd("enew")
                    vim.fn.termopen(shell_cmd(), { cwd = cwd })
                    enable_terminal_ui()
                    vim.opt_local.scrolloff = 3
                    vim.b.term_cwd = cwd
                    vim.cmd("startinsert")
                    pcall(vim.cmd, "bdelete! " .. old_buf)
                end)
                return
            end

            -- OSC 7: directory tracking
            local url = seq:match("\x1b%]7;(file://[^\x07\x1b]+)")
            if not url then return end
            local raw = url:match("^file://[^/]*(/.+)$")
            if not raw then return end
            local path = normalize_osc7_path(raw)
            vim.cmd("lcd " .. vim.fn.fnameescape(path))
            vim.b.term_cwd = path
        end,
    })

    -- Start Neovide directly in terminal
    vim.api.nvim_create_autocmd("VimEnter", {
        group = terminal_ui_group,
        callback = function()
            vim.cmd("cd ~")
            update_title()
            vim.cmd("enew")
            vim.fn.termopen(shell_cmd())

            enable_terminal_ui()

            vim.cmd("startinsert")
        end,
    })
end
