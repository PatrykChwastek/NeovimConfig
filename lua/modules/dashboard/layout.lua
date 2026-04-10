local M   = {}
local sec = require("modules.dashboard.sections")

-- ── config ───────────────────────────────────────────────────────────────────
local LPAD       = 1    -- left margin in wide mode
local WIDE_MIN   = 120  -- columns below this → stacked layout
local WIDE_SPLIT = 0.52 -- fraction of width for left column
local KEY_MARGIN = 4    -- cells from right edge where keys appear
-- ─────────────────────────────────────────────────────────────────────────────

local function pad(str, width)
    local w = vim.fn.strdisplaywidth(str)
    if w >= width then return str end
    return str .. string.rep(" ", width - w)
end

local function shorten_path(filepath, max_w)
    local short = vim.fn.fnamemodify(filepath, ":~")
    if vim.fn.strdisplaywidth(short) <= max_w then return short end
    local sep   = short:find("\\") and "\\" or "/"
    local parts = vim.split(short, "[/\\]")
    local fname = table.remove(parts)
    local abbr  = {}
    for _, p in ipairs(parts) do
        abbr[#abbr + 1] = p == "" and "" or p:sub(1, 1)
    end
    return table.concat(abbr, sep) .. sep .. fname
end

local function get_file_icon(filepath)
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then return " ", "Normal" end
    local icon, hl = devicons.get_icon(
        vim.fn.fnamemodify(filepath, ":t"),
        vim.fn.fnamemodify(filepath, ":e"),
        { default = true }
    )
    return icon or " ", hl or "Normal"
end

local colors = {
    orange = "#DA702C",
    red    = "#D14D41",
    white  = "#f0efea",
    muted  = "#878580",
}
-- ── highlight groups ─────────────────────────────────────────────────────────
vim.api.nvim_set_hl(0, "DashHeader",       { fg = colors.orange })
vim.api.nvim_set_hl(0, "DashNavIcon",      { fg = colors.red    })
vim.api.nvim_set_hl(0, "DashNavLabel",     { fg = colors.white  })
vim.api.nvim_set_hl(0, "DashNavKey",       { fg = colors.red    })
vim.api.nvim_set_hl(0, "DashFilePath",     { fg = colors.white  })
vim.api.nvim_set_hl(0, "DashFileKey",      { fg = colors.red    })
vim.api.nvim_set_hl(0, "DashProjectPath",  { fg = colors.muted  })
vim.api.nvim_set_hl(0, "DashJokeSetup",    { fg = colors.muted,  italic = true })
vim.api.nvim_set_hl(0, "DashJokeDelivery", { fg = colors.white,  italic = true })
-- ─────────────────────────────────────────────────────────────────────────────

local function add_nav(lines, hls, actions, key_col, indent)
    local pad_str = string.rep(" ", indent)
    for _, item in ipairs(sec.nav) do
        local ln   = #lines
        local ic_s = indent + 2
        local ic_e = ic_s + #item.icon  -- byte length, not display width
        local lb_s = ic_e + 1
        local lb_e = lb_s + #item.label

        local padded = pad(pad_str .. "  " .. item.icon .. " " .. item.label, key_col)
        lines[#lines + 1] = padded .. item.key .. "  "
        lines[#lines + 1] = ""

        local key_byte = #padded
        hls[#hls + 1] = { ln, ic_s,     ic_e,          "DashNavIcon"  }
        hls[#hls + 1] = { ln, lb_s,     lb_e,          "DashNavLabel" }
        hls[#hls + 1] = { ln, key_byte, key_byte + 1,  "DashNavKey"   }

        actions[item.key] = item.action
    end
end

local function add_files(lines, hls, actions, key_col)
    local ln = #lines
    lines[#lines + 1] = "Recent Files"
    hls[#hls + 1] = { ln, 0, -1, "DashHeader" }

    local files = sec.recent_files(5)
    for i, filepath in ipairs(files) do
        ln = #lines
        local icon, icon_hl = get_file_icon(filepath)
        local ic_s   = 2
        local ic_e   = ic_s + #icon
        local short  = shorten_path(filepath, key_col - #icon - 3)
        local path_s = ic_e + 1
        local path_e = path_s + #short
        local padded = pad("  " .. icon .. " " .. short, key_col)

        lines[#lines + 1] = padded .. tostring(i)

        local key_byte = #padded
        hls[#hls + 1] = { ln, ic_s,     ic_e,         icon_hl        }
        hls[#hls + 1] = { ln, path_s,   path_e,       "DashFilePath" }
        hls[#hls + 1] = { ln, key_byte, key_byte + 1, "DashFileKey"  }

        actions[tostring(i)] = function() vim.cmd("edit " .. vim.fn.fnameescape(filepath)) end
    end
end

-- ── section builders ─────────────────────────────────────────────────────────
-- Each takes (width) and returns lines, hls, actions.
-- To add a section: implement this pattern, then register it in WIDE_*/STACK_ORDER.

local function section_header(w)
    local lines, hls = {}, {}
    local logo_w = 0
    for _, line in ipairs(sec.header) do
        logo_w = math.max(logo_w, vim.fn.strdisplaywidth(line))
    end
    local off  = math.max(2, math.floor((w - logo_w) / 2))
    local lpad = string.rep(" ", off)
    for _, line in ipairs(sec.header) do
        local ln = #lines
        lines[#lines + 1] = lpad .. line
        hls[#hls + 1] = { ln, off, off + #line, "DashHeader" }
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = ""
    return lines, hls, {}
end

local function section_nav(w)
    local lines, hls, actions = {}, {}, {}
    add_nav(lines, hls, actions, w - KEY_MARGIN, LPAD)
    return lines, hls, actions
end

local function section_files(w)
    local lines, hls, actions = {}, {}, {}
    add_files(lines, hls, actions, w - KEY_MARGIN)
    return lines, hls, actions
end

local function section_projects(w)
    local projects = sec.recent_projects(5)
    if #projects == 0 then return {}, {}, {} end

    local lines, hls, actions = {}, {}, {}
    lines[#lines + 1] = ""

    local ln = #lines
    lines[#lines + 1] = " Projects"
    hls[#hls + 1] = { ln, 0, -1, "DashHeader" }

    local icon = "󰉋 "
    local keys = { "6", "7", "8", "9", "0" }
    local key_col = w - KEY_MARGIN

    for i, project in ipairs(projects) do
        ln = #lines
        local name   = project.name
        local path   = shorten_path(project.path, key_col - #icon - #name - 4)
        local prefix = "  " .. icon .. " " .. name .. "  " .. path
        local padded = pad(prefix, key_col)

        lines[#lines + 1] = padded .. keys[i]

        local ic_s   = 2
        local ic_e   = ic_s + #icon
        local name_s = ic_e + 1
        local name_e = name_s + #name
        local path_s = name_e + 2
        local path_e = path_s + #path
        local key_b  = #padded

        hls[#hls + 1] = { ln, ic_s,  ic_e,      "DashNavIcon"     }
        hls[#hls + 1] = { ln, name_s, name_e,   "DashNavLabel"    }
        hls[#hls + 1] = { ln, path_s, path_e,   "DashProjectPath" }
        hls[#hls + 1] = { ln, key_b,  key_b + 1, "DashFileKey"    }

        actions[keys[i]] = function() require("modules.projects").open(project) end
    end
    return lines, hls, actions
end

local function section_joke(w)
    local joke = require("modules.dashboard.joke").cache
    local lines, hls = {}, {}

    local function add_centered(text, hl)
        local off = math.max(0, math.floor((w - vim.fn.strdisplaywidth(text)) / 2))
        local ln  = #lines
        lines[#lines + 1] = string.rep(" ", off) .. text
        hls[#hls + 1] = { ln, off, off + #text, hl }
    end

    lines[#lines + 1] = ""
    if not joke then
        add_centered("Here should be a joke but you need to fix it yourself..", "DashJokeSetup")
    elseif joke.type == "single" then
        add_centered(joke.text, "DashJokeDelivery")
    elseif joke.type == "twopart" then
        add_centered(joke.setup,    "DashJokeSetup")
        lines[#lines + 1] = ""
        add_centered(joke.delivery, "DashJokeDelivery")
    end
    lines[#lines + 1] = ""

    return lines, hls, {}
end

-- ── layout config ─────────────────────────────────────────────────────────────
local WIDE_TOP    = { section_header }
local WIDE_LEFT   = { section_nav }
local WIDE_RIGHT  = { section_files, section_projects }
local STACK_ORDER = { section_header, section_nav, section_files, section_projects }
-- ─────────────────────────────────────────────────────────────────────────────

-- Concatenate sections vertically, adjusting highlight row offsets.
local function build_column(builders, width)
    local lines, hls, actions = {}, {}, {}
    for _, build in ipairs(builders) do
        local sl, sh, sa = build(width)
        local off = #lines
        vim.list_extend(lines, sl)
        for _, h in ipairs(sh) do
            hls[#hls + 1] = { h[1] + off, h[2], h[3], h[4] }
        end
        actions = vim.tbl_extend("force", actions, sa)
    end
    return lines, hls, actions
end

-- Merge two column outputs side by side with byte-correct highlight offsets.
local function merge_columns(ll, lh, rl, rh, left_w)
    local total = math.max(#ll, #rl)
    local lines, hls, right_byte_off = {}, {}, {}
    for i = 1, total do
        local padded_l = pad(ll[i] or "", left_w)
        lines[#lines + 1] = padded_l .. (rl[i] or "")
        right_byte_off[i] = #padded_l
    end
    for _, h in ipairs(lh) do hls[#hls + 1] = { h[1], h[2], h[3], h[4] } end
    for _, h in ipairs(rh) do
        local boff = right_byte_off[h[1] + 1] or left_w
        hls[#hls + 1] = { h[1], h[2] + boff, h[3] == -1 and -1 or h[3] + boff, h[4] }
    end
    return lines, hls
end

-- ── wide: logo on top, two columns below ─────────────────────────────────────
local function build_wide(cols)
    local left_w  = math.floor(cols * WIDE_SPLIT)
    local right_w = cols - left_w

    local tl, th, ta = build_column(WIDE_TOP,   cols)
    local ll, lh, la = build_column(WIDE_LEFT,  left_w)
    local rl, rh, ra = build_column(WIDE_RIGHT, right_w)

    local bot_lines, bot_hls = merge_columns(ll, lh, rl, rh, left_w)

    local lines, hls = {}, {}
    vim.list_extend(lines, tl)
    vim.list_extend(lines, bot_lines)

    for _, h in ipairs(th) do hls[#hls + 1] = h end
    local off = #tl
    for _, h in ipairs(bot_hls) do
        hls[#hls + 1] = { h[1] + off, h[2], h[3], h[4] }
    end

    return lines, hls, vim.tbl_extend("force", ta, vim.tbl_extend("force", la, ra))
end

-- ── narrow: stacked ──────────────────────────────────────────────────────────
local function build_stacked(cols)
    return build_column(STACK_ORDER, cols)
end

-- ── render ───────────────────────────────────────────────────────────────────
function M.render(buf, win)
    local cols = vim.o.columns
    local rows = vim.o.lines - 2

    local lines, hls, actions
    if cols >= WIDE_MIN then
        lines, hls, actions = build_wide(cols)
    else
        lines, hls, actions = build_stacked(cols)
    end

    -- Joke footer: always pinned to the bottom of the screen.
    local jl, jh = section_joke(cols)
    local joke_rows = #jl  -- 0 when no joke yet

    local content_rows = rows - joke_rows
    local top_pad = math.max(0, math.floor((content_rows - #lines) / 2))
    for _ = 1, top_pad do table.insert(lines, 1, "") end
    for _, h in ipairs(hls) do h[1] = h[1] + top_pad end

    -- Pad the gap between main content and joke footer.
    local gap = rows - #lines - joke_rows
    for _ = 1, math.max(0, gap) do lines[#lines + 1] = "" end

    -- Append joke lines with adjusted row offsets.
    local joke_off = #lines
    vim.list_extend(lines, jl)
    for _, h in ipairs(jh) do
        hls[#hls + 1] = { h[1] + joke_off, h[2], h[3], h[4] }
    end

    local ns = vim.api.nvim_create_namespace("dashboard_hl")
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buflisted  = false

    for _, h in ipairs(hls) do
        pcall(vim.api.nvim_buf_add_highlight, buf, ns, h[4], h[1], h[2], h[3])
    end

    for key, action in pairs(actions) do
        vim.keymap.set("n", key, action, { buffer = buf, noremap = true, silent = true, nowait = true })
    end

    local wo = vim.wo[win]
    wo.number         = false
    wo.relativenumber = false
    wo.cursorline     = false
    wo.signcolumn     = "no"
    wo.foldcolumn     = "0"
    wo.wrap           = false
    wo.statusline     = " "
end

return M
