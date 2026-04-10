local M = {}

M.header = {
"                                                                          ",
"       ████ ██████           █████      ██                          ",
"      ███████████             █████                                  ",
"      █████████ ███████████████████ ███   ███████████        ",
"     █████████  ███    █████████████ █████ ██████████████        ",
"    █████████ ██████████ █████████ █████ █████ ████ █████        ",
"  ███████████ ███    ███ █████████ █████ █████ ████ █████       ",
" ██████  █████████████████████ ████ █████ █████ ████ ██████ btw..",
}

M.nav = {
    { icon = "󰈞 ", label = "Find File",    key = "f", action = function() require("telescope.builtin").find_files() end },
    { icon = "󰝒 ", label = "New File",     key = "n", action = function() vim.cmd("enew") end },
    { icon = "󰊄 ", label = "Find Text",    key = "g", action = function() require("telescope.builtin").live_grep() end },
    { icon = "󰋚 ", label = "Recent Files", key = "r", action = function() require("telescope.builtin").oldfiles() end },
    { icon = "󰒓 ", label = "Config",       key = "c", action = function() require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") }) end },
    { icon = "󰗼 ", label = "Quit",         key = "q", action = function() vim.cmd("qa") end },
}

function M.recent_projects(n)
    return require("modules.projects").recent(n)
end

function M.recent_files(n)
    local result = {}
    for _, f in ipairs(vim.v.oldfiles) do
        if vim.fn.filereadable(f) == 1 then
            result[#result + 1] = f
            if #result >= n then break end
        end
    end
    return result
end

return M
