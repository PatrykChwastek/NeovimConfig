-- Smart paste: ]p pastes as new line(s) below, [p above — re-indented to
-- match the current line's indentation. Works for charwise and linewise.

local function smart_paste(above)
    local reg     = vim.v.register ~= "" and vim.v.register or '"'
    local content = vim.fn.getreg(reg)
    if content == "" then return end

    local lines = vim.split(content:gsub("\n$", ""), "\n", { plain = true })

    -- Strip common leading whitespace
    local min_indent = math.huge
    for _, line in ipairs(lines) do
        if line:match("%S") then
            min_indent = math.min(min_indent, #line:match("^%s*"))
        end
    end
    if min_indent == math.huge then min_indent = 0 end

    -- Re-indent to current line's base
    local base = vim.api.nvim_get_current_line():match("^%s*")
    local result = {}
    for _, line in ipairs(lines) do
        result[#result + 1] = line:match("%S") and (base .. line:sub(min_indent + 1)) or ""
    end

    local row = vim.api.nvim_win_get_cursor(0)[1]
    local insert_at = above and row - 1 or row
    vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, result)
    vim.api.nvim_win_set_cursor(0, { insert_at + 1, #base })
end

vim.keymap.set("n", "]p", function() smart_paste(false) end, { noremap = true, desc = "Smart paste below" })
vim.keymap.set("n", "[p", function() smart_paste(true)  end, { noremap = true, desc = "Smart paste above" })
