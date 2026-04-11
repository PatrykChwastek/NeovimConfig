return {
    {
        'nvim-mini/mini.nvim',
        version = false,
        event = "VeryLazy",
        config = function()
            require('mini.move').setup(
                {
                    -- Module mappings. Use `''` (empty string) to disable one.
                    mappings = {
                        -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
                        left = '<M-Left>',
                        right = '<M-Right>',
                        down = '<M-Down>',
                        up = '<M-UP>',

                        -- Move current line in Normal mode
                        line_left = '<M-Left>',
                        line_right = '<M-Right>',
                        line_down = '<M-Down>',
                        line_up = '<M-UP>',
                    }
                })

            require('mini.comment').setup({
                mappings = {
                    -- Toggle comment (like `gcip` - comment inner paragraph) for both
                    comment = '<C-_>',
                    -- Toggle comment on current line
                    comment_line = '<C-_>',
                    -- Toggle comment on visual selection
                    comment_visual = '<C-_>',
                    -- Define 'comment' textobject (like `dgc` - delete whole comment block)
                    -- Works also in Visual mode if mapping differs from `comment_visual`
                    textobject = '<C-_>',
                },
            })
            require('mini.files').setup({
                mappings = {
                    go_in       = '<Right>',
                    go_out      = '<Left>',
                },
                windows = {
                    -- Maximum number of windows to show side by side
                    max_number = 4,
                    -- Whether to show preview of file/directory under cursor
                    preview = true,
                    -- Width of focused window
                    width_focus = 50,
                    -- Width of non-focused window
                    width_nofocus = 15,
                    -- Width of preview window
                    width_preview = 75,
                }
            })

            local mini_snippets = require('mini.snippets')
            local gen_loader = mini_snippets.gen_loader
            local base_loader = gen_loader.from_lang()
            -- 2. Create a wrapper that fixes language name mismatches
            local custom_lang_loader = function(context)
                local lang = context.lang
                if lang == 'c_sharp' then 
                    lang = 'csharp' 
                end
                return base_loader({ buf_id = context.buf_id, lang = lang })
            end

            mini_snippets.setup({
                snippets = {
                    custom_lang_loader,
                    gen_loader.from_lang({ lang = 'global' }),
                },
            })
            -- Automatically stop snippet session when leaving Insert mode
            vim.api.nvim_create_autocmd("InsertLeave", {
                group = vim.api.nvim_create_augroup("StopMiniSnippets", { clear = true }),
                callback = function()
                    if MiniSnippets ~= nil and MiniSnippets.session.get(false) ~= nil then
                        MiniSnippets.session.stop()
                    end
                end,
            })

            local hipatterns = require('mini.hipatterns')
            hipatterns.setup({
                highlighters = {
                    -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
                    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
                    hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
                    todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
                    note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },
                    hex_color = hipatterns.gen_highlighter.hex_color(),
                },
            })

            require('mini.extra').setup()

            local gen_ai_spec = require('mini.extra').gen_ai_spec
            require('mini.ai').setup({
                custom_textobjects = {
                    B = gen_ai_spec.buffer(),
                    D = gen_ai_spec.diagnostic(),
                    I = gen_ai_spec.indent(),
                    L = gen_ai_spec.line(),
                    N = gen_ai_spec.number(),
                },
            })
            require('mini.diff').setup()
            require('mini.surround').setup()
            require('mini.bracketed').setup()
            require('mini.pairs').setup()
            require('mini.cursorword').setup()
            require('mini.indentscope').setup({
                symbol = "│",
                options = { try_as_border = true },
            })
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "text", "help", "dashboard" },
                callback = function() vim.b.miniindentscope_disable = true end,
            })
        end
    }
}
