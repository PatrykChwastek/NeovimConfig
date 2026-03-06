return {
    {
        'rmagatti/alternate-toggler',
        config = function()
            require("alternate-toggler").setup {
                alternates = {
                    ["=="] = "!=",
                    ["||"] = "&&",
                    ["&&"] = "||"
                }
            }
        end,
        event = { "BufReadPost" }, -- lazy load after reading a buffer
    },
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            { "nvim-telescope/telescope.nvim", version = "*", dependencies = { "nvim-lua/plenary.nvim" } }, -- optional: you can also use fzf-lua, snacks, mini-pick instead.
        },
        ft = "python",                             -- Load when opening Python files
        keys = { { ",v", "<cmd>VenvSelect<cr>" } },-- Open picker on keymap
        opts = {},
    },
    {
        "hat0uma/csvview.nvim",
        ---@module "csvview"
        ---@type CsvView.Options
        opts = {
            parser = {
                comments = { "#", "//" },
                delimiter = {
                    ft = {
                        csv = ',',
                        dat = ''
                    }
                },
                display_mode = "highlight"
            },
            keymaps = {
                -- Text objects for selecting fields
                textobject_field_inner = { "if", mode = { "o", "x" } },
                textobject_field_outer = { "af", mode = { "o", "x" } },
                --  Navigation:
                jump_next_field_end = { "<C-Right>", mode = { "n", "v" } }, -- horizontal
                jump_prev_field_end = { "<C-Left>", mode = { "n", "v" } },
                jump_next_row = { "<C-Down>", mode = { "n", "v" } },     -- vertical
                jump_prev_row = { "<C-Up>", mode = { "n", "v" } },
            },
        },
        cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    }
}
