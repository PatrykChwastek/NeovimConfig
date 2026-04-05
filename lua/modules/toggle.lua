local M = {}

local alternates = {
    -- Booleans
    ["true"] = "false",   ["false"] = "true",
    ["True"] = "False",   ["False"] = "True",
    ["TRUE"] = "FALSE",   ["FALSE"] = "TRUE",
    -- Yes / No
    ["yes"] = "no",       ["no"] = "yes",
    ["Yes"] = "No",       ["No"] = "Yes",
    ["YES"] = "NO",       ["NO"] = "YES",
    -- On / Off
    ["on"] = "off",       ["off"] = "on",
    ["On"] = "Off",       ["Off"] = "On",
    ["ON"] = "OFF",       ["OFF"] = "ON",
    -- Numbers
    ["0"] = "1",          ["1"] = "0",
    -- Operators
    ["=="] = "!=",        ["!="] = "==",
    ["==="] = "!==",      ["!=="] = "===",
    ["||"] = "&&",        ["&&"] = "||",
}

function M.toggle()
    local col  = vim.api.nvim_win_get_cursor(0)[2] + 1  -- 1-indexed
    local line = vim.api.nvim_get_current_line()

    -- Try longer matches first so "!=" is preferred over "="
    local sorted = {}
    for from, to in pairs(alternates) do
        table.insert(sorted, { from = from, to = to })
    end
    table.sort(sorted, function(a, b) return #a.from > #b.from end)

    for _, alt in ipairs(sorted) do
        local search_from = math.max(1, col - #alt.from + 1)
        local s, e = line:find(vim.pesc(alt.from), search_from)
        if s and s <= col and e >= col then
            vim.api.nvim_set_current_line(line:sub(1, s - 1) .. alt.to .. line:sub(e + 1))
            return
        end
    end
end

return M
