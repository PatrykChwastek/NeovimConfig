local M = {}

-- nil = not yet fetched, table = { type, ... }
M.cache = nil

local URL = "https://v2.jokeapi.dev/joke/Programming?safe-mode"

function M.fetch_async(on_done)
    if M.cache then
        on_done(M.cache)
        return
    end
    vim.system(
        { "curl", "-s", "--max-time", "5", URL },
        { text = true },
        function(result)
            if result.code ~= 0 or result.stdout == "" then return end
            vim.schedule(function()
                local ok, data = pcall(vim.fn.json_decode, result.stdout)
                if not ok or data.error then return end
                if data.type == "single" then
                    M.cache = { type = "single", text = data.joke:gsub("[\r\n]", " ") }
                elseif data.type == "twopart" then
                    M.cache = {
                        type     = "twopart",
                        setup    = data.setup:gsub("[\r\n]", " "),
                        delivery = data.delivery:gsub("[\r\n]", " "),
                    }
                end
                if M.cache then on_done(M.cache) end
            end)
        end
    )
end

function M.refresh(on_done)
    M.cache = nil
    M.fetch_async(on_done or function() end)
end

return M
