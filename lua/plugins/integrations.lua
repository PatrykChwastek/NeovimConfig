return {
    {
        'TimUntersberger/neogit',
        lazy = true,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
        },
        keys = {
            { "<leader>g",  group = "Git" },
            { "<leader>gg", function() require('neogit').open() end,    desc = "󰊢 Open Neogit" },
            { "<leader>gf", ":!git pull<CR>", desc = "Git pull" },
        },
        opts = {
            integrations = { diffview = true }
        }
    },
    {
        "dlyongemallo/diffview.nvim",
        version = "*",
        config = function ()
            require("diffview").setup({
              view = {
                merge_tool = {
                  layout = "diff3_horizontal",
                  disable_diagnostics = true,
                  winbar_info = true,
                },
                cycle_layouts = {
                  merge_tool = { "diff4_mixed", "diff3_mixed", "diff3_horizontal", "diff1_plain" },
                },
              },
            })
        end
    },
    {
      "obsidian-nvim/obsidian.nvim",
      version = "*",
      ft = "markdown",
      cmd = "Obsidian",
      ---@module 'obsidian'
      ---@type obsidian.config
      opts = {
        legacy_commands = false,
        templates = {
          folder = "templates",
          substitutions = {
            week_monday = function()
              local t = os.date("*t")
              local ts = os.time() - ((t.wday - 2) % 7) * 86400
              return os.date("%Y-%m-%d", ts)
            end,
            week_friday = function()
              local t = os.date("*t")
              local ts = os.time() - ((t.wday - 2) % 7) * 86400 + 4 * 86400
              return os.date("%Y-%m-%d", ts)
            end,
          },
        },
       workspaces = require('local_vars').obsidian,
      },
    }
}
