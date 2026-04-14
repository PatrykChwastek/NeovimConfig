local M = {}

local data_file = vim.fn.stdpath("data") .. "/projects.json"

function M.load()
    if vim.fn.filereadable(data_file) == 0 then return {} end
    local lines = vim.fn.readfile(data_file)
    if #lines == 0 then return {} end
    local ok, data = pcall(vim.fn.json_decode, lines[1])
    return ok and data or {}
end

function M.save(projects)
    vim.fn.writefile({ vim.fn.json_encode(projects) }, data_file)
end

function M.add(name, path)
    local projects = M.load()
    for _, p in ipairs(projects) do
        if p.path == path then
            vim.notify("Project already exists: " .. p.name, vim.log.levels.WARN)
            return
        end
    end
    table.insert(projects, 1, { name = name, path = path, last_opened = os.time() })
    M.save(projects)
    vim.notify("Project added: " .. name)
end

function M.remove(path)
    local projects = M.load()
    for i, p in ipairs(projects) do
        if p.path == path then
            table.remove(projects, i)
            M.save(projects)
            vim.notify("Project removed: " .. p.name)
            return
        end
    end
end

function M.open(project)
    local projects = M.load()
    for _, p in ipairs(projects) do
        if p.path == project.path then
            p.last_opened = os.time()
            break
        end
    end
    M.save(projects)
    vim.cmd("cd " .. vim.fn.fnameescape(project.path))
    vim.notify("Project: " .. project.name)
    require("telescope.builtin").find_files()
end

function M.recent(n)
    local projects = M.load()
    table.sort(projects, function(a, b)
        return (a.last_opened or 0) > (b.last_opened or 0)
    end)
    local result = {}
    for i = 1, math.min(n, #projects) do
        result[i] = projects[i]
    end
    return result
end

-- Multi-step create: path input → name input → save
function M.create()
    local cwd = vim.fn.getcwd()
    vim.ui.input({ prompt = "Project path: ", default = cwd }, function(path)
        if not path or path == "" then return end
        -- normalise: expand ~, strip trailing slash
        path = vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("[/\\]$", "")
        local default_name = vim.fn.fnamemodify(path, ":t")
        vim.ui.input({ prompt = "Project name: ", default = default_name }, function(name)
            if not name or name == "" then return end
            M.add(name, path)
        end)
    end)
end

-- Detect if the file/dir is known project on nvim startup, cds to the project root when a match is found.
function M.detect_root()
    local start_path
    if vim.fn.argc() > 0 then
        local arg = vim.fn.fnamemodify(vim.fn.argv(0), ":p")
        start_path = vim.fn.isdirectory(arg) == 1 and arg or vim.fn.fnamemodify(arg, ":h")
    else
        start_path = vim.fn.getcwd()
    end
    start_path = start_path:gsub("[/\\]$", "")

    local projects = M.load()
    local best     = nil  -- longest project path that is a prefix of start_path

    for _, p in ipairs(projects) do
        local norm = p.path:gsub("[/\\]$", "")
        if start_path == norm or start_path:find("^" .. vim.pesc(norm) .. "[/\\]") then
            if not best or #norm > #best.path then
                best = { name = p.name, path = norm }
            end
        end
    end

    if best then
        vim.cmd("cd " .. vim.fn.fnameescape(best.path))
    end
end

function M.setup()
    vim.api.nvim_create_autocmd("VimEnter", {
        once     = true,
        callback = M.detect_root,
    })

    vim.api.nvim_create_user_command("ProjectCreate", M.create,  { desc = "Add current dir as project" })
    vim.api.nvim_create_user_command("ProjectPick",   function()
        require("modules.projects.telescope").pick()
    end, { desc = "Switch project" })
    vim.api.nvim_create_user_command("ProjectRemove", function()
        require("modules.projects.telescope").remove()
    end, { desc = "Remove a project" })
end

return M
