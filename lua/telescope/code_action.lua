local M = {}

local PREVIEW_NS = vim.api.nvim_create_namespace("code_action_preview")
local resolve_cache = {}

local function apply_action(action, client)
    local function exec(a)
        if a.edit then
            vim.lsp.util.apply_workspace_edit(a.edit, client.offset_encoding)
        end
        if a.command then
            local cmd = type(a.command) == "table" and a.command or a
            client:request("workspace/executeCommand", cmd, nil, 0)
        end
    end

    if action.edit or action.command then
        exec(action)
    else
        client:request("codeAction/resolve", action, function(err, resolved)
            if not err and resolved then exec(resolved) end
        end, 0)
    end
end

local function apply_edit_to_scratch(original_lines, text_edits, offset_encoding)
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, original_lines)
    vim.lsp.util.apply_text_edits(text_edits, scratch, offset_encoding)
    local new_lines = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
    vim.api.nvim_buf_delete(scratch, { force = true })
    return new_lines
end

--- [preview builder] ---

local function build_preview(edit, offset_encoding)
    local lines_out = {}
    local hls       = {}
    local ft        = ""

    local changes = {}
    if edit.documentChanges then
        for _, dc in ipairs(edit.documentChanges) do
            if dc.textDocument then
                changes[dc.textDocument.uri] = dc.edits
            end
        end
    elseif edit.changes then
        changes = edit.changes
    end

    local first = true
    for uri, text_edits in pairs(changes) do
        local fname    = vim.uri_to_fname(uri)
        local existing = vim.fn.bufnr(fname)
        local original_lines

        if existing ~= -1 and vim.api.nvim_buf_is_loaded(existing) then
            original_lines = vim.api.nvim_buf_get_lines(existing, 0, -1, false)
        else
            local ok, content = pcall(vim.fn.readfile, fname)
            original_lines = ok and content or {}
        end

        local new_lines = apply_edit_to_scratch(original_lines, text_edits, offset_encoding)

        if ft == "" then
            ft = vim.filetype.match({ filename = fname }) or ""
        end

        -- file separator
        if not first then
            vim.list_extend(lines_out, { "", string.rep("─", 60), "" })
        end
        first = false

        local short = vim.fn.fnamemodify(fname, ":~:.")
        table.insert(lines_out, "-- " .. short)
        local offset = #lines_out   -- lines already written before file content

        vim.list_extend(lines_out, new_lines)

        -- diff to find which lines in the new content are changed/added/deleted
        local hunks = vim.diff(
            table.concat(original_lines, "\n") .. "\n",
            table.concat(new_lines, "\n") .. "\n",
            { result_type = "indices" }
        ) or {}

        for _, h in ipairs(hunks) do
            local b_start, b_count = h[3], h[4]
            local a_count          = h[2]

            -- highlight added / changed lines
            for i = 0, b_count - 1 do
                table.insert(hls, { lnum = offset + b_start - 1 + i, hl = "DiffAdd" })
            end

            -- for pure deletions there is no new line; mark the surrounding line
            if b_count == 0 and a_count > 0 then
                local mark_lnum = offset + b_start - 1  -- line just before deletion (0-indexed)
                if mark_lnum >= 0 then
                    table.insert(hls, { lnum = mark_lnum, hl = "DiffDelete" })
                end
            end
        end
    end

    return lines_out, hls, ft
end

--- [previewer] ---

local function render(pbuf, lines, hls, ft)
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(pbuf) then return end
        vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
        vim.api.nvim_buf_clear_namespace(pbuf, PREVIEW_NS, 0, -1)
        if ft ~= "" then vim.bo[pbuf].filetype = ft end
        for _, h in ipairs(hls) do
            vim.api.nvim_buf_add_highlight(pbuf, PREVIEW_NS, h.hl, h.lnum, 0, -1)
        end
    end)
end

local function make_previewer(offset_encoding)
    return require("telescope.previewers").new_buffer_previewer({
        title = "Preview",
        define_preview = function(self, entry)
            local pbuf   = self.state.bufnr
            local item   = entry.value
            local action = item.action
            local client = vim.lsp.get_client_by_id(item.client_id)

            local function fallback(msg)
                render(pbuf, { msg }, {}, "")
            end

            if action.edit then
                local lines, hls, ft = build_preview(action.edit, offset_encoding)
                if #lines > 0 then render(pbuf, lines, hls, ft)
                else fallback("No file changes") end
                return
            end

            if action.command then
                local name = type(action.command) == "string"
                    and action.command or (action.command.command or "?")
                fallback("Command: " .. name)
                return
            end

            -- needs codeAction/resolve
            local key = action.title .. "|" .. (action.kind or "")
            if resolve_cache[key] then
                local c = resolve_cache[key]
                render(pbuf, c.lines, c.hls, c.ft)
                return
            end

            fallback("Resolving…")
            client:request("codeAction/resolve", action, function(err, resolved)
                if err or not resolved or not resolved.edit then
                    resolve_cache[key] = { lines = { "No preview available" }, hls = {}, ft = "" }
                else
                    local lines, hls, ft = build_preview(resolved.edit, offset_encoding)
                    resolve_cache[key] = { lines = #lines > 0 and lines or { "No file changes" }, hls = hls, ft = ft }
                end
                local c = resolve_cache[key]
                render(pbuf, c.lines, c.hls, c.ft)
            end, 0)
        end,
    })
end

function M.code_action()
    resolve_cache = {}

    local mode = vim.api.nvim_get_mode().mode
    local params

    if mode == "v" or mode == "V" then
        local s = vim.fn.getpos("v")
        local e = vim.fn.getpos(".")
        if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then s, e = e, s end
        params = vim.lsp.util.make_given_range_params(
            { s[2] - 1, s[3] - 1 },
            { e[2] - 1, e[3] - 1 }
        )
    else
        params = vim.lsp.util.make_range_params()
    end

    params.context = {
        diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 }),
        triggerKind  = 1,
    }

    vim.lsp.buf_request_all(0, "textDocument/codeAction", params, function(results)
        local actions         = {}
        local offset_encoding = "utf-16"

        for client_id, result in pairs(results) do
            local client = vim.lsp.get_client_by_id(client_id)
            if client then offset_encoding = client.offset_encoding end
            for _, action in ipairs(result.result or {}) do
                table.insert(actions, { action = action, client_id = client_id })
            end
        end

        if #actions == 0 then
            vim.notify("No code actions available", vim.log.levels.INFO)
            return
        end

        local pickers   = require("telescope.pickers")
        local finders   = require("telescope.finders")
        local conf      = require("telescope.config").values
        local t_actions = require("telescope.actions")
        local state     = require("telescope.actions.state")

        pickers.new({}, {
            prompt_title = "Code Actions",
            previewer    = make_previewer(offset_encoding),
            finder = finders.new_table({
                results = actions,
                entry_maker = function(entry)
                    local title = entry.action.title:gsub("\n", " ")
                    return { value = entry, display = title, ordinal = title }
                end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
                t_actions.select_default:replace(function()
                    t_actions.close(prompt_bufnr)
                    local sel = state.get_selected_entry()
                    if not sel then return end
                    local client = vim.lsp.get_client_by_id(sel.value.client_id)
                    if client then apply_action(sel.value.action, client) end
                end)
                return true
            end,
        }):find()
    end)
end

return M
