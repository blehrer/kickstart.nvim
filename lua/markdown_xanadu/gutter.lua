local config = require('markdown_xanadu.config')

local M = {}

local ns = vim.api.nvim_create_namespace('markdown_xanadu.gutter')

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

---@class markdown_xanadu.GutterCell
---@field char string
---@field hl string
---@field priority integer

---@param pairs { id: string, rel_l: integer, rel_r: integer }[]
---@param active_id? string
---@param show_inactive boolean
---@return table<integer, markdown_xanadu.GutterCell> grid
---@return integer min_rel
---@return integer max_rel
function M.build_grid(pairs, active_id, show_inactive)
  local grid = {}
  local min_rel, max_rel = math.huge, 0

  local function set_cell(rel, char, hl, priority)
    min_rel = math.min(min_rel, rel)
    max_rel = math.max(max_rel, rel)
    local cur = grid[rel]
    if not cur or priority >= cur.priority then
      grid[rel] = { char = char, hl = hl, priority = priority }
    end
  end

  for _, pair in ipairs(pairs) do
    local is_active = active_id ~= nil and pair.id == active_id
    if not show_inactive and not is_active then
      goto continue
    end
    local hl = is_active and 'MarkdownXanaduLinkActive' or 'MarkdownXanaduLinkInactive'
    local priority = is_active and 2 or 1
    local rel_l, rel_r = pair.rel_l, pair.rel_r
    local lo, hi = math.min(rel_l, rel_r), math.max(rel_l, rel_r)
    if lo == hi then
      set_cell(lo, '─', hl, priority)
    else
      set_cell(lo, '┐', hl, priority)
      for y = lo + 1, hi - 1 do
        set_cell(y, '│', hl, priority)
      end
      set_cell(hi, '┘', hl, priority)
    end
    ::continue::
  end

  if min_rel == math.huge then
    return {}, 0, 0
  end
  return grid, min_rel, max_rel
end

local state = {
  win = nil,
  buf = nil,
  timer = nil,
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

--- Buffer line → 1-indexed editor screen row for {win}.
local function screen_row_for_line(win, bufline)
  if not valid_win(win) then
    return bufline
  end
  return vim.api.nvim_win_call(win, function()
    local saved = vim.api.nvim_win_get_cursor(win)
    vim.api.nvim_win_set_cursor(win, { bufline, 0 })
    local row = vim.fn.screenrow()
    vim.api.nvim_win_set_cursor(win, saved)
    return row
  end)
end

local function hover_panels_open()
  local ok, hover = pcall(require, 'config.hover')
  return ok and hover.is_open()
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
---@param pairs { id: string, left_win: integer, right_win: integer, left_line: integer, right_line: integer }[]
---@param active_id? string
function M.redraw(main_win, pairs, active_id)
  if not valid_win(main_win) or #pairs == 0 then
    M.close()
    return
  end

  if hover_panels_open() then
    M.close()
    return
  end

  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = 'nofile'
    vim.bo[state.buf].bufhidden = 'hide'
  end

  local cfg = config.get()
  local main_pos = vim.api.nvim_win_get_position(main_win)
  local col = main_pos[2] + vim.api.nvim_win_get_width(main_win)
  local top = main_pos[1]

  local rel_pairs = {}
  for _, pair in ipairs(pairs) do
    if valid_win(pair.left_win) and valid_win(pair.right_win) then
      local lr = screen_row_for_line(pair.left_win, pair.left_line)
      local rr = screen_row_for_line(pair.right_win, pair.right_line)
      rel_pairs[#rel_pairs + 1] = {
        id = pair.id,
        rel_l = lr - top,
        rel_r = rr - top,
      }
    end
  end

  local grid, min_rel, max_rel = M.build_grid(rel_pairs, active_id, cfg.gutter_inactive)
  if not next(grid) then
    M.close()
    return
  end

  local float_height = max_rel - min_rel + 1
  local trimmed = {}
  for i = min_rel, max_rel do
    trimmed[#trimmed + 1] = (grid[i] and grid[i].char) or ' '
  end
  local float_row = top + min_rel - 1

  if not valid_win(state.win) then
    state.win = vim.api.nvim_open_win(state.buf, false, {
      relative = 'editor',
      row = float_row,
      col = col,
      width = 1,
      height = float_height,
      focusable = false,
      zindex = 10,
      style = 'minimal',
    })
    vim.wo[state.win].winblend = 0
  else
    vim.api.nvim_win_set_config(state.win, {
      relative = 'editor',
      row = float_row,
      col = col,
      width = 1,
      height = float_height,
    })
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, trimmed)
  vim.bo[state.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for i = min_rel, max_rel do
    local cell = grid[i]
    if cell then
      vim.api.nvim_buf_set_extmark(state.buf, ns, i - min_rel, 0, {
        end_row = i - min_rel,
        end_col = 1,
        hl_group = cell.hl,
        priority = cell.priority,
      })
    end
  end
end

---@param main_win integer
---@param pairs { id: string, left_win: integer, right_win: integer, left_line: integer, right_line: integer }[]
---@param active_id? string
function M.schedule(main_win, pairs, active_id)
  if state.timer then
    state.timer:close()
  end
  state.timer = vim.defer_fn(function()
    state.timer = nil
    M.redraw(main_win, pairs, active_id)
  end, 50)
end

return M
