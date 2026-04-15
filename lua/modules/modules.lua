require('modules.mini_diff_scrollview').setup()
require('modules.smart_paste')
require('modules.glow')
require('modules.projects').setup()
require('modules.dashboard').setup()
require('modules.opener').setup({
    wrap_filetypes = { "lazy", "mason" },
})