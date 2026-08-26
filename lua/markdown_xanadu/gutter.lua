local config = require('markdown_xanadu.config')

local M = {}

---@param left_row integer 1-indexed screen row
---@param right_row integer 1-indexed screen row
---@return string[]
function M.connector_chars(left_row, right_row)
  if left_row == right_row then
    return { '─' }
  end
  local chars = { '┐' }
  local lo, hi = math.min(left_row, right_row), math.max(left_row, right_row)
  for _ = lo + 1, hi - 1 do
    chars[#chars + 1] = '│'
  end
  chars[#chars + 1] = '┘'
  return chars
end

---@param pair_list { left_row: integer, right_row: integer }[]
---@return string[]
function M.chars_for_pairs(pair_list)
  local set = {}
  for _, pair in ipairs(pair_list) do
    for _, c in ipairs(M.connector_chars(pair.left_row, pair.right_row)) do
      set[c] = true
    end
  end
  local out = {}
  for c in pairs(set) do
    out[#out + 1] = c
  end
  table.sort(out)
  return out
end

local state = {
  win = nil,
  buf = nil,
  timer = nil,
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

function M.close()
  if state.timer then
    state.timer:close()
    state.timer = nil
  end
  if valid_win(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

---@param main_win integer
---@param pairs { left_win: integer, right_win: integer, left_line: integer, right_line: integer }[]
function M.redraw(main_win, pairs)
  if not valid_win(main_win) or #pairs == 0 then
    M.close()
    return
  end

  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = 'nofile'
    vim.bo[state.buf].bufhidden = 'hide'
  end

  local main_pos = vim.api.nvim_win_get_position(main_win)
  local right_win = pairs[1].right_win
  if not valid_win(right_win) then
    M.close()
    return
  end
  local right_pos = vim.api.nvim_win_get_position(right_win)
  local col = main_pos[2] + vim.api.nvim_win_get_width(main_win)
  local top = math.min(main_pos[1], right_pos[1])
  local height = vim.o.lines - top - 1

  local lines = {}
  for i = 1, height do
    lines[i] = ' '
  end

  for _, pair in ipairs(pairs) do
    if valid_win(pair.left_win) and valid_win(pair.right_win) then
      local lr = vim.fn.winline(pair.left_line, pair.left_win)
      local rr = vim.fn.winline(pair.right_line, pair.right_win)
      if lr <= 0 then
        lr = pair.left_line
      end
      if rr <= 0 then
        rr = pair.right_line
      end
      local rel_l = lr - top
      local rel_r = rr - top
      if rel_l >= 1 and rel_l <= height then
        lines[rel_l] = '─'
      end
      if rel_r >= 1 and rel_r <= height then
        lines[rel_r] = '─'
      end
      local lo, hi = math.min(rel_l, rel_r), math.max(rel_l, rel_r)
      if lo >= 1 and hi <= height then
        lines[lo] = '┐'
        for y = lo + 1, hi - 1 do
          lines[y] = '│'
        end
        if hi ~= lo then
          lines[hi] = '┘'
        end
      end
    end
  end

  if not valid_win(state.win) then
    state.win = vim.api.nvim_open_win(state.buf, false, {
      relative = 'editor',
      row = top,
      col = col,
      width = 1,
      height = height,
      focusable = false,
      zindex = 300,
      style = 'minimal',
    })
    vim.wo[state.win].winblend = 0
  else
    vim.api.nvim_win_set_config(state.win, {
      relative = 'editor',
      row = top,
      col = col,
      width = 1,
      height = height,
    })
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
end

---@param main_win integer
---@param pairs { left_win: integer, right_win: integer, left_line: integer, right_line: integer }[]
function M.schedule(main_win, pairs)
  if state.timer then
    state.timer:close()
  end
  state.timer = vim.defer_fn(function()
    state.timer = nil
    M.redraw(main_win, pairs)
  end, 50)
end

return M
