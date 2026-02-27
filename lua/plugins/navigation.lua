return {
    -- Inline file explorer
    --     {
    --     "stevearc/oil.nvim",
    --     opts = {
    --         columns = {
    --             "icon",
    --             "permissions",
    --             "size",
    --             "mtime"
    --         },
    --         keymaps = {
    --             ["q"] = "actions.close",
    --             ["<esc>"] = "actions.close"
    --         }
    --     },
    --     keys = {
    --         { "<leader>p", function() require('oil').open('.') end, desc = "Open oil browser at project root" },
    --         { "<leader>-", function() require('oil').open() end, desc = "Open oil browser at file root" },
    --     }
    -- },
    -- Fuzzy finding files
    {
        'nvim-telescope/telescope.nvim',
        version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        config = function()
            local actions = require("telescope.actions")
            require('telescope').setup {
                defaults = {
                mappings = {
                    i = {
                    ["<esc>"] = actions.close,
                    ["<C-v>"] = actions.select_vertical
                    },
                },
                layout_strategy = 'horizontal',
                layout_config = {
                        horizontal = {
                            width = { padding = 0 },
                            height = { padding = 0 },
                            preview_width = 0.5,
                        },
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,                    -- enable fuzzy matching
                        override_generic_sorter = false, -- false because we’ll use CLI fzf
                        override_file_sorter = false,    -- false so normal sorter is used
                        case_mode = "smart_case",
                    }
                }
            }

        require "telescope.multigrep".setup()
        require "telescope.sessions".setup()
        end
    },
    {
    "folke/flash.nvim",
    opts = {
      jump = {
        -- automatically jump when there is only one match
        autojump = true,
      },
      label = {
        -- allow uppercase labels
        uppercase = false,
      },
      modes = {
        char = {
          jump_labels = true,
          multi_line = true,
        },
      },
    },
    keys = {
            { "<CR>", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            { "<BS>", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
            { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
            { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
  }
}
