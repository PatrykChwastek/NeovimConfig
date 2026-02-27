-- visual mode selection color
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a2a" })

return {
    -- Themes
    {
        "serhez/teide.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },-- Using lazy.nvim
    {
        'ribru17/bamboo.nvim',
        lazy = false,
        priority = 1000,
        config = function()
            require('bamboo').setup {
                style = 'vulgaris',
                transparent = true,
                code_style = {
                    comments = {
                        italic = true
                    }
                },
                highlights = {
                    ['@comment'] = { fg = '$grey' },
                    ['SnacksIndentScope'] = { fg = '#521300' }, -- intend color
                    ['orange'] = { fg = '#DA702C' },
                    ['SnacksDashboardHeader'] = { fg = '#DA702C' }
                }
            }
            require('bamboo').load()
        end,
    },
    -- Bottom bar
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons", "Mofiqul/vscode.nvim" },
        opts = {},
        config = function()
            local colors = {
                blue   = '#4385BE',
                cyan   = '#3AA99F',
                black  = '#100F0F',
                white  = '#f0efea',
                red    = '#D14D41',
                orange = '#DA702C',
                grey   = '#303030',
                black2 = '#1A1817',
            }
            local bubbles_theme = {
                normal = {
                    a = { fg = colors.black, bg = colors.orange },
                    b = { fg = colors.white, bg = colors.grey },
                    c = { fg = colors.black, bg = colors.black },
                },

                insert =  { a = { fg = colors.black, bg = colors.blue } },
                visual =  { a = { fg = colors.black, bg = colors.cyan } },
                replace = { a = { fg = colors.black, bg = colors.red } },

                inactive = {
                    a = { fg = colors.white, bg = colors.black },
                    b = { fg = colors.white, bg = colors.black },
                    c = { fg = colors.black, bg = colors.black },
                },
            }
            require('lualine').setup {
                options = {
                    theme = bubbles_theme,
                    component_separators = '|',
                    section_separators = { left = '', right = '' },
                },
                sections = {
                    lualine_a = {
                        { 'mode', separator = { left = '', right= ''}},
                    },
                    lualine_b = { 'filename', 'branch','diff'},
                    lualine_c = { 'fileformat'},
                    lualine_x = {},
                    lualine_y = { 'filetype', 'progress' },
                    lualine_z = {
                        { 'location', separator = { left = '', right= ''}},
                    },
                },
                inactive_sections = {
                    lualine_a = { 'filename' },
                    lualine_b = {},
                    lualine_c = {},
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = { 'location' },
                },
                tabline = {},
                extensions = {},
            }
        end
    },
    -- Key binding helper
    {
        "folke/which-key.nvim",
        lazy = false,
        opts = {}
    },
    -- Code highlight, coloring
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",
        config = function()
            require('nvim-treesitter.install').compilers = { "zig", "gcc", "clang" }
            local configs = require('nvim-treesitter.configs')
            configs.setup({
                ensure_installed = { "c_sharp", "javascript", "typescript", "json", "lua", "tsx", "html", "python" },
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
            })
        end
    },
    -- Fancy diagnostic and more with hierarchy 
    {
        "folke/trouble.nvim",
        opts = {
            auto_close = true,
            auto_open = false,
            focus = true, -- Focus the window when opened
            keys = {
                ["<leader>"] = "jump_close"
            }
        },
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },
    -- Telescope code action
    {
        "rachartier/tiny-code-action.nvim",
        dependencies = {
            {"nvim-lua/plenary.nvim"},
            {"nvim-telescope/telescope.nvim"}
        },
        event = "LspAttach",
        opts = {},
        config = function()
            require("tiny-code-action").setup()
        end
    },
    -- Centered command vim line
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            -- add any options here
        },
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
            "MunifTanjim/nui.nvim",
        }
    },
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        ---@type snacks.Config
        opts = {
            dashboard = {
                enabled = true,
                preset = {
                    header = [[
                                                                              
           ████ ██████           █████      ██                          
          ███████████             █████                                  
          █████████ ███████████████████ ███   ███████████        
         █████████  ███    █████████████ █████ ██████████████        
        █████████ ██████████ █████████ █████ █████ ████ █████        
      ███████████ ███    ███ █████████ █████ █████ ████ █████       
     ██████  █████████████████████ ████ █████ █████ ████ ██████ btw..
      ]],
                },
                sections = {
                    { section = "header"},
                    { section = "keys", gap = 1, padding = 1 },
                    { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1},
                    { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 12, padding = 1},
                    { section = "startup" },
                }
            },
            scroll = {
                enabled = true,
                animate = {
                    duration = { step = 10, total = 100 },
                    easing = "linear",
                },
                animate_repeat = {
                    delay = 100, -- delay in ms before using the repeat animation
                    duration = { step = 5, total = 50 },
                    easing = "linear",
                }
            },
            notifier = {
                enabled = true
            },
            input = {
                enabled = true
            },
            indent = {
                enabled = true,
                only_current = true,
                hl = "SnacksIndentScope",
            }
        }
    }
}
