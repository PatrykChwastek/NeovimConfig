local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local function telescope_sessions()
    local sessions = require('mini.sessions')
    
    -- Get list of session names from mini.sessions
    local session_list = {}
    for name, _ in pairs(sessions.detected) do
        table.insert(session_list, name)
    end

    pickers.new({}, {
        prompt_title = "Mini Sessions",
        finder = finders.new_table {
            results = session_list
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                sessions.read(selection[1])
            end)
            return true
        end,
    }):find()
end



M.setup = function()
    -- Keymap to trigger the Telescope session list
    vim.keymap.set('n', '<Leader>sl', telescope_sessions, { desc = 'Sessions: Telescope' })
end

return M
