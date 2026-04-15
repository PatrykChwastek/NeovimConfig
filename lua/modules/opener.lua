local M = {}

-- Matches http/https URLs (including fragments, query strings, parens for Wikipedia-style links).
local URL_PAT   = "https?://[%w%-_.~:/?#%[%]@!$&'()*+,;=%%]+"
-- Trailing punctuation that is almost never part of a URL when it closes the token.
local URL_TRAIL = "[%)%]%.,%!\"']*$"

local function open_url(url)
    url = url:gsub(URL_TRAIL, "")
    local cmd
    if vim.fn.has("win32") == 1 then
        cmd = { "cmd", "/c", "start", "", url }
    elseif vim.fn.has("mac") == 1 then
        cmd = { "open", url }
    else
        cmd = { "xdg-open", url }
    end
    vim.system(cmd)
    vim.notify("Opening: " .. url)
end

local function open_path(path)
    local expanded = vim.fn.expand(path)
    if vim.fn.isdirectory(expanded) == 1 or vim.fn.filereadable(expanded) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(expanded))
    else
        vim.notify("Not found: " .. expanded, vim.log.levels.WARN)
    end
end

local function token_at(line, col)
    local stop = ' \t"\'`<>|'
    local s, e = col + 1, col + 1
    while s > 1     and not stop:find(line:sub(s - 1, s - 1), 1, true) do s = s - 1 end
    while e < #line and not stop:find(line:sub(e + 1, e + 1), 1, true) do e = e + 1 end
    return line:sub(s, e)
end

-- Returns true if a URL or path was found and acted on; false otherwise.
local function try_open()
    local line = vim.api.nvim_get_current_line()
    local col  = vim.api.nvim_win_get_cursor(0)[2]

    local pos = 1
    while true do
        local ms, me = line:find(URL_PAT, pos)
        if not ms then break end
        if col + 1 >= ms and col + 1 <= me then
            open_url(line:sub(ms, me))
            return true
        end
        pos = me + 1
    end

    local token = token_at(line, col)
    if token:match("^[~/]") or token:match("^[A-Za-z]:[/\\]") then
        open_path(token)
        return true
    end

    return false
end

-- Build a callable from an existing maparg() dict so we can invoke it as a fallback.
local function build_fallback(map)
    if not map or map.lhs == "" then
        return function()
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false
            )
        end
    end

    -- Lua-function mapping (most modern plugins use this).
    if type(map.callback) == "function" then
        return map.callback
    end

    -- rhs string mapping (older style or expr maps).
    if map.rhs and map.rhs ~= "" then
        local rhs  = map.rhs
        local expr = map.expr == 1
        return function()
            local keys = expr and vim.api.nvim_eval(rhs) or rhs
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes(keys, true, true, true), "m", false
            )
        end
    end

    return function()
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false
        )
    end
end

-- Wrap the buffer-local <CR> in `buf` so opener runs first, then the original action.
-- Uses vim.schedule so the plugin has time to finish setting its own mappings.
local function wrap_buf(buf)
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end

        local existing = vim.fn.maparg("<CR>", "n", false, true)
        local fallback = build_fallback(existing)

        vim.keymap.set("n", "<CR>", function()
            if not try_open() then fallback() end
        end, { buffer = buf, noremap = true, silent = true, nowait = true,
               desc = "Open URL/path or original <CR>" })
    end)
end

function M.setup(opts)
    opts = opts or {}
    local key = opts.key or "<CR>"

    -- Global mapping for normal editing buffers.
    vim.keymap.set("n", key, function()
        if not try_open() then
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false
            )
        end
    end, { desc = "Open URL or path under cursor" })

    -- For plugin UIs that set their own buffer-local <CR>, wrap rather than replace.
    -- Add more filetypes here as needed.
    local wrap_ft = opts.wrap_filetypes or {}
    vim.api.nvim_create_autocmd("FileType", {
        pattern  = wrap_ft,
        callback = function(ev) wrap_buf(ev.buf) end,
    })
end

return M
