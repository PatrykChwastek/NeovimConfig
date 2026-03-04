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
        },
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                preselect = cmp.PreselectMode.None,
                mapping = {
                    ['<C-j>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
                    ['<C-k>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
                    ['<C-Right>'] = cmp.mapping.complete(),
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            fallback()
                        end
                    end),
                    ['<S-Tab>'] = cmp.mapping(function()
                        if cmp.visible() then
                            cmp.select_prev_item()
                        end
                    end),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                    { name = "conjure" },
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
    }
}
