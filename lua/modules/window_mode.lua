local M = {}

M.is_active = false
M.applied_bufs = {}
M.wk_autocmd_id = nil
M.zen_state = nil

-- Zen Toggle
local function collect_bufs(node, win_to_buf, result)
  if node[1] == 'leaf' then
    result[#result + 1] = win_to_buf[node[2]]
  else
    for _, child in ipairs(node[2]) do
      collect_bufs(child, win_to_buf, result)
    end
  end
end

-- Pre-creates all siblings at each layout level before recursing, so nested
-- col/row structures land in the right positions.
local function rebuild_layout(node, bufs, idx)
  if node[1] == 'leaf' then
    local buf = bufs[idx[1]]
    idx[1] = idx[1] + 1
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_win_set_buf, 0, buf)
    end
    return
  end

  local children = node[2]
  local split_cmd = node[1] == 'row' and 'rightbelow vsplit' or 'rightbelow split'

  local wins = { vim.api.nvim_get_current_win() }
  for i = 2, #children do
    vim.cmd(split_cmd)
    wins[i] = vim.api.nvim_get_current_win()
  end

  for i, child in ipairs(children) do
    vim.api.nvim_set_current_win(wins[i])
    rebuild_layout(child, bufs, idx)
  end
end

function M.toggle_zen()
  if not M.is_active then return end
  vim.schedule(function()
    -- Exit window mode first so keymaps are torn down before layout ops.
    M.exit_window_mode()

    vim.defer_fn(function()
      if M.zen_state then
        local state = M.zen_state
        M.zen_state = nil
        vim.cmd("wincmd o")
        rebuild_layout(state.layout, state.bufs, { 1 })
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == state.cur_buf then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
        vim.notify("Exited Zen Mode", vim.log.levels.INFO, { title = "Window Mode" })
      else
        local layout = vim.fn.winlayout()
        local cur_win = vim.api.nvim_get_current_win()
        local win_to_buf = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(win).relative == '' then
            win_to_buf[win] = vim.api.nvim_win_get_buf(win)
          end
        end
        local bufs = {}
        collect_bufs(layout, win_to_buf, bufs)
        M.zen_state = { layout = layout, bufs = bufs, cur_buf = win_to_buf[cur_win] }
        vim.cmd("wincmd o")
        vim.notify("Zen Mode", vim.log.levels.INFO, { title = "Window Mode" })
      end
    end, 20)
  end)
end

local dir_splits = {
  h = 'leftabove vnew',   j = 'rightbelow new',
  k = 'leftabove new',    l = 'rightbelow vnew',
  ['<Left>']  = 'leftabove vnew',  ['<Down>']  = 'rightbelow new',
  ['<Up>']    = 'leftabove new',   ['<Right>'] = 'rightbelow vnew',
}

local function make_dir_handler(telescope)
  return function()
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or char == '' then return end
    local split_cmd = dir_splits[char] or dir_splits[vim.fn.keytrans(char)]
    if not split_cmd then return end
    vim.schedule(function()
      vim.cmd(split_cmd)
      M.exit_window_mode()
      if telescope then vim.cmd("Telescope find_files") end
    end)
  end
end

-- Resize: always move the border in the key's direction
local function make_resize(dir)
  return function()
    local cmd
    if dir == 'H' then
      cmd = vim.fn.winnr('h') ~= vim.fn.winnr() and 'wincmd >' or 'wincmd <'
    elseif dir == 'L' then
      cmd = vim.fn.winnr('h') ~= vim.fn.winnr() and 'wincmd <' or 'wincmd >'
    elseif dir == 'K' then
      cmd = vim.fn.winnr('k') ~= vim.fn.winnr() and 'wincmd +' or 'wincmd -'
    elseif dir == 'J' then
      cmd = vim.fn.winnr('k') ~= vim.fn.winnr() and 'wincmd -' or 'wincmd +'
    end
    vim.cmd(cmd)
  end
end

local window_keys = {
  -- Navigation
  { 'h', '<C-w>h', 'Focus Left' },
  { 'j', '<C-w>j', 'Focus Down' },
  { 'k', '<C-w>k', 'Focus Up' },
  { 'l', '<C-w>l', 'Focus Right' },
  { '<Left>', '<C-w>h', 'Focus Left' },
  { '<Down>', '<C-w>j', 'Focus Down' },
  { '<Up>', '<C-w>k', 'Focus Up' },
  { '<Right>', '<C-w>l', 'Focus Right' },

  -- Moving
  { '<M-h>', '<C-w>H', 'Move Window Left' },
  { '<M-j>', '<C-w>J', 'Move Window Down' },
  { '<M-k>', '<C-w>K', 'Move Window Up' },
  { '<M-l>', '<C-w>L', 'Move Window Right' },
  { '<M-Left>', '<C-w>H', 'Move Window Left' },
  { '<M-Down>', '<C-w>J', 'Move Window Down' },
  { '<M-Up>', '<C-w>K', 'Move Window Up' },
  { '<M-Right>', '<C-w>L', 'Move Window Right' },

  -- Resizing
  { 'H',       make_resize('H'), 'Move Border Left' },
  { 'J',       make_resize('J'), 'Move Border Down' },
  { 'K',       make_resize('K'), 'Move Border Up' },
  { 'L',       make_resize('L'), 'Move Border Right' },
  { '<S-Left>',  make_resize('H'), 'Move Border Left' },
  { '<S-Down>',  make_resize('J'), 'Move Border Down' },
  { '<S-Up>',    make_resize('K'), 'Move Border Up' },
  { '<S-Right>', make_resize('L'), 'Move Border Right' },

  -- Actions
  { 'x', '<C-w>c', 'Close Current Window' },
  { 'X', '<C-w>o', 'Close All Other Windows' },
  { 'z', M.toggle_zen, 'Toggle Zen/Fullscreen' },

  -- New split (n) / Telescope split (N)
  { 'n', make_dir_handler(false), 'New Empty (+ dir)' },
  { 'N', make_dir_handler(true),  'Telescope (+ dir)' },
}

-- Buffer-local Map Management
local function apply_to_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if M.applied_bufs[buf] then return end
  M.applied_bufs[buf] = true

  for _, map in ipairs(window_keys) do
    vim.keymap.set('n', map[1], map[2], {
      desc    = "WinMode: " .. map[3],
      noremap = true,
      silent  = true,
      nowait  = true,
      buffer  = buf,
    })
  end

  local exit_opts = { noremap = true, silent = true, nowait = true, buffer = buf }
  vim.keymap.set('n', '<Esc>', M.exit_window_mode, vim.tbl_extend('force', exit_opts, { desc = "WinMode: Exit" }))
  vim.keymap.set('n', 'q',    M.exit_window_mode, vim.tbl_extend('force', exit_opts, { desc = "WinMode: Exit" }))
end

local function remove_from_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  for _, map in ipairs(window_keys) do
    pcall(vim.api.nvim_buf_del_keymap, buf, 'n', map[1])
  end
  pcall(vim.api.nvim_buf_del_keymap, buf, 'n', '<Esc>')
  pcall(vim.api.nvim_buf_del_keymap, buf, 'n', 'q')
end

-- Mode Toggles
function M.exit_window_mode()
  if not M.is_active then return end
  M.is_active = false

  if M.wk_autocmd_id then
    pcall(vim.api.nvim_del_autocmd, M.wk_autocmd_id)
    M.wk_autocmd_id = nil
  end

  vim.schedule(function()
    for buf in pairs(M.applied_bufs) do
      remove_from_buf(buf)
    end
    M.applied_bufs = {}
    vim.notify("Exited Window Mode", vim.log.levels.INFO, { title = "Window Mode" })
  end)
end

function M.enter_window_mode()
  if M.is_active then return end
  M.is_active = true
  M.applied_bufs = {}

  vim.schedule(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      apply_to_buf(vim.api.nvim_win_get_buf(win))
    end

    -- Apply to buffers in windows opened after entering window mode
    M.wk_autocmd_id = vim.api.nvim_create_autocmd('WinEnter', {
      callback = function()
        if M.is_active then
          apply_to_buf(vim.api.nvim_get_current_buf())
        end
      end,
    })

    local msg = "Entered Window Mode.\nNav/Move/Resize: hjkl / Alt+hjkl / Shift+hjkl\nNew/Telescope: n+dir / N+dir\nClose: x/X | Zen: z | Exit: q / Esc"
    vim.notify(msg, vim.log.levels.WARN, { title = "Window Mode" })
  end)
end

function M.toggle_window_mode()
  if M.is_active then M.exit_window_mode() else M.enter_window_mode() end
end

return M
