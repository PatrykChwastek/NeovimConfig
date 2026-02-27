return {
    {
        'nvim-mini/mini.nvim',
        version = false,
        config = function()
            require('mini.sessions').setup({
                -- Whether to read default session if Neovim opened without file arguments
                autoread = false,
                -- Whether to write currently read session before leaving it
                autowrite = true,
                -- Directory where global sessions are stored (use `''` to disable)
                directory = vim.fn.stdpath('data') .. '/sessions',
                -- File for local session (use `''` to disable)
                file = '',

                -- Whether to force possibly harmful actions (meaning depends on function)
                force = { read = false, write = true, delete = false },

                -- Hook functions for actions. Default `nil` means 'do nothing'.
                hooks = {
                    -- Before successful action
                    pre = { read = nil, write = nil, delete = nil },
                    -- After successful action
                    post = { read = nil, write = nil, delete = nil },
                },

                -- Whether to print session path after action
                verbose = { read = false, write = true, delete = true },
            })

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

            require('mini.diff').setup()
            require('mini.ai').setup()
            require('mini.surround').setup()
            require('mini.bracketed').setup()
            require('mini.pairs').setup()
        end
    }
}
