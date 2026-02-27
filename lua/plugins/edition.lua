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
    }
}
