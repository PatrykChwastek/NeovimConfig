return {
    {
        "mason-org/mason.nvim",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup({
                registries = {
                    "github:mason-org/mason-registry",
                    "github:Crashdummyy/mason-registry"
                }
            })

        end
    },
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        config = function()
            local mason_lspconfig = require("mason-lspconfig")

            mason_lspconfig.setup({
                ensure_installed = {
                    --> Python
                    "basedpyright",
                    "ruff",
                    --<
                    -- "cspell",
                   -- "ltex-ls",
                    -- "typescript-language-server",
                }
            })

            vim.lsp.config['basedpyright']= {
                settings = {
                    basedpyright = {
                        analysis = {
                            typeCheckingMode = "off",
                        }
                    }
                }
            }

            vim.lsp.config['ruff']= {
                on_attach = function(client, bufnr)
                    if client.server_capabilities.hoverProvider then
                        client.server_capabilities.hoverProvider = false
                    end
                end
            }
        end,
    },
    -- .net lsp
    -- :MasonInstall roslyn
    -- redried .net 10 sdk
    {
        "seblj/roslyn.nvim",
        opts = {
            config = {
                settings = {
                    ["csharp|background_analysis"] = {
                        --dotnet_analyzer_diagnostics_scope = "none",
                        dotnet_compiler_diagnostics_scope = "openFiles"
                    },
                    ["csharp|code_lens"] = {
                        dotnet_enable_references_code_lens = true,
                    },
                }
            }
        }
    },
    -- Autocompletion 
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
            'hrsh7th/cmp-cmdline',
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "abeldekat/cmp-mini-snippets",
        },
        event = "VeryLazy",
        config = function()
            local cmp = require('cmp')
            -- to make c-space work in Win termina add to actions:
            -- {
            --     "command": {
            --         "action": "sendInput",
            --         "input": "\u001b[32;5u"
            --     },
            --     "keys": "ctrl+space"
            -- }
            -- vim.keymap.set('i', '<C-Space>', function() cmp.mapping.complete() end, { noremap = true })

            cmp.setup({
                preselect = cmp.PreselectMode.None,
                mapping = {
                    ['<C-j>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
                    ['<C-k>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<CR>'] = cmp.mapping.confirm({ select = false }),


                    -- Navigate completion menu with Arrow Keys
                    ['<Down>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            fallback()
                        end
                    end, { 'i', 'c' }),

                    ['<Up>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end, { 'i', 'c' }),

                    --  Confirm with Tab, or jump to next snippet field
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.confirm({ select = true }) 
                        elseif MiniSnippets ~= nil and MiniSnippets.session.get(false) ~= nil then
                            MiniSnippets.session.jump('next')
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),

                    --  Shift-Tab exclusively jumps backward in snippets['<S-Tab>'] = cmp.mapping(function(fallback)
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if MiniSnippets ~= nil and MiniSnippets.session.get(false) ~= nil then
                            MiniSnippets.session.jump('prev')
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),

                    --  Escape closes the menu without leaving insert mode
                    ['<Esc>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.abort()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                },
                snippet = {
                    expand = function(args)
                        local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
                        insert({ body = args.body }) -- Insert at cursor

                        -- These two lines are recommended by cmp-mini-snippets to 
                        -- correctly refresh the autocomplete menu after snippet insertion
                        cmp.resubscribe({ "TextChangedI", "TextChangedP" })
                        require("cmp.config").set_onetime({ sources = {} })
                    end,
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                    { name = "conjure" },
                    { name = "mini_snippets" },
                    { name = 'nvim_lsp_signature_help' }
                }
            })
            -- `/` cmdline setup.
            cmp.setup.cmdline('/', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' }
                }
            })
            -- `:` cmdline setup.
            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' }
                }, {
                        {
                            name = 'cmdline',
                            option = {
                                ignore_cmds = { 'Man', '!' }
                            }
                        }
                    })
            })
        end
    },
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "davidmh/cspell.nvim", -- Helper to make cspell work easier with none-ls
        },
        event = "VeryLazy",
        config = function()
            local null_ls = require("null-ls")
            local cspell = require("cspell")

            -- Setup cspell configuration
            local cspell_config = {
                cspell_config_dirs = { "~/.config/" },
                find_json = require("cspell").default_find_json, -- or your override
            }

            null_ls.setup({
                sources = {
                    cspell.diagnostics.with({
                    config = cspell_config,
                    diagnostics_postprocess = function(diagnostic)
                        -- You can use "WARN", "INFO", or "HINT"
                        diagnostic.severity = vim.diagnostic.severity["HINT"]
                    end,
                    }),
                    cspell.code_actions.with({ config = cspell_config }),
                },
            })
        end
    },
    { "rafamadriz/friendly-snippets" }
}
