-- Glow highlights for yank (exact range), undo, and redo.
-- Yank: charwise = exact text, linewise = full lines, blockwise = block.
-- Undo/redo: line-level only ('[ '] marks don't expose change granularity).

-- ── config ──────────────────────────────────────────────────────────────────
local duration = 300  -- ms

local colors = {
    yank = "#7A683A",
    undo = "#6B3D00",
    redo = "#7A5020",
}

-- Dark-tinted cursorline backgrounds — same hue family as lualine mode colors.
local mode_bg = {
    normal  = "#2e2010",  -- dark orange  · lualine normal  #DA702C
    insert  = "#10202e",  -- dark blue    · lualine insert  #4385BE
    visual  = "#10201e",  -- dark cyan    · lualine visual  #3AA99F
    replace = "#2e1010",  -- dark red     · lualine replace #D14D41
}
-- ────────────────────────────────────────────────────────────────────────────

vim.api.nvim_set_hl(0, "YankHL", { bg = colors.yank, fg = "NONE" })
vim.api.nvim_set_hl(0, "UndoHL", { bg = colors.undo, fg = "NONE" })
vim.api.nvim_set_hl(0, "RedoHL", { bg = colors.redo, fg = "NONE" })

-- ── mode-tinted cursorline ───────────────────────────────────────────────────
local function cursorline_bg(m)
    local c = m:sub(1, 1)
    if     c == "i" or c == "t"               then return mode_bg.insert
    elseif c == "v" or c == "V" or c == "\22" then return mode_bg.visual
    elseif c == "R"                            then return mode_bg.replace
    else                                            return mode_bg.normal
    end
end

local function refresh_cursorline()
    vim.api.nvim_set_hl(0, "CursorLine", { bg = cursorline_bg(vim.fn.mode()) })
end

vim.opt.cursorline = true
refresh_cursorline()

vim.api.nvim_create_autocmd("ModeChanged", {
    callback = refresh_cursorline,
})
-- ────────────────────────────────────────────────────────────────────────────

local ns       = vim.api.nvim_create_namespace("glow_hl")
local timer    = nil
local last_buf = nil

local function clear(bufnr)
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
    if bufnr then
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
    last_buf = nil
end

local function flash(bufnr, hl_group)
    clear(last_buf)
    last_buf = bufnr

    local s = vim.api.nvim_buf_get_mark(bufnr, "[")
    local e = vim.api.nvim_buf_get_mark(bufnr, "]")
    if s[1] == 0 and e[1] == 0 then return end

    for row = s[1] - 1, e[1] - 1 do
        vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, row, 0, -1)
    end

    timer = vim.uv.new_timer()
    timer:start(duration, 0, vim.schedule_wrap(function()
        clear(bufnr)
    end))
end

vim.keymap.set("n", "u", function()
    vim.cmd("undo")
    vim.schedule(function() flash(vim.api.nvim_get_current_buf(), "UndoHL") end)
end, { noremap = true })

vim.keymap.set("n", "<C-r>", function()
    vim.cmd("redo")
    vim.schedule(function() flash(vim.api.nvim_get_current_buf(), "RedoHL") end)
end, { noremap = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
    callback = function()
        if vim.v.event.operator ~= "y" then return end

        local bufnr   = vim.api.nvim_get_current_buf()
        local s       = vim.api.nvim_buf_get_mark(bufnr, "[")
        local e       = vim.api.nvim_buf_get_mark(bufnr, "]")
        local regtype = vim.v.event.regtype

        clear(last_buf)
        last_buf = bufnr

        if regtype == "V" then
            for row = s[1] - 1, e[1] - 1 do
                vim.api.nvim_buf_add_highlight(bufnr, ns, "YankHL", row, 0, -1)
            end
        elseif regtype:sub(1, 1) == "\22" then
            local sc, ec = s[2], e[2] + 1
            for row = s[1] - 1, e[1] - 1 do
                vim.api.nvim_buf_add_highlight(bufnr, ns, "YankHL", row, sc, ec)
            end
        else
            local sr, sc = s[1] - 1, s[2]
            local er, ec = e[1] - 1, e[2] + 1
            if sr == er then
                vim.api.nvim_buf_add_highlight(bufnr, ns, "YankHL", sr, sc, ec)
            else
                vim.api.nvim_buf_add_highlight(bufnr, ns, "YankHL", sr, sc, -1)
                for row = sr + 1, er - 1 do
                    vim.api.nvim_buf_add_highlight(bufnr, ns, "YankHL", row, 0, -1)
                end
                vim.api.nvim_buf_add_highlight(bufnr, ns, "YankHL", er, 0, ec)
            end
        end

        timer = vim.uv.new_timer()
        timer:start(duration, 0, vim.schedule_wrap(function()
            clear(bufnr)
        end))
    end,
})
