local M = {}

local function sorted_projects()
    local projects = require("modules.projects").load()
    table.sort(projects, function(a, b)
        return (a.last_opened or 0) > (b.last_opened or 0)
    end)
    return projects
end

local function entry_maker(project)
    local display = string.format("%-25s %s", project.name, vim.fn.fnamemodify(project.path, ":~"))
    return {
        value   = project,
        display = display,
        ordinal = project.name .. " " .. project.path,
    }
end

function M.pick()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf    = require("telescope.config").values
    local actions = require("telescope.actions")
    local state   = require("telescope.actions.state")

    pickers.new({}, {
        prompt_title = "Projects",
        finder = finders.new_table({
            results      = sorted_projects(),
            entry_maker  = entry_maker,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local sel = state.get_selected_entry()
                if sel then require("modules.projects").open(sel.value) end
            end)
            return true
        end,
    }):find()
end

function M.remove()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf    = require("telescope.config").values
    local actions = require("telescope.actions")
    local state   = require("telescope.actions.state")

    pickers.new({}, {
        prompt_title = "Remove Project",
        finder = finders.new_table({
            results     = sorted_projects(),
            entry_maker = entry_maker,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local sel = state.get_selected_entry()
                if sel then require("modules.projects").remove(sel.value.path) end
            end)
            return true
        end,
    }):find()
end

return M
