local detect = require('merge-tool-help.detect')

local M = {}

---@class MergeSlot
---@field index number
---@field win_id number
---@field bufnr number
---@field role string
---@field bufname string
---@field row number
---@field col number
---@field width number
---@field height number

---@class MergeTreeLeaf
---@field type 'leaf'
---@field slot MergeSlot

---@class MergeTreeSplit
---@field type 'hsplit'|'vsplit'
---@field children table[]

---@param exclude_win_id number|nil
---@return MergeSlot[]
local function collect_windows(exclude_win_id)
  detect.ensure_output_bufnr()

  local wins = {}
  local tabpage = vim.api.nvim_get_current_tabpage()

  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if win_id ~= exclude_win_id and vim.api.nvim_win_is_valid(win_id) and vim.wo[win_id].diff then
      local pos = vim.api.nvim_win_get_position(win_id)
      local row = pos[1]
      local col = pos[2]
      local bufnr = vim.api.nvim_win_get_buf(win_id)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      table.insert(wins, {
        win_id = win_id,
        bufnr = bufnr,
        role = detect.role_of_buf(bufnr),
        bufname = bufname ~= '' and bufname or '[No Name]',
        row = row,
        col = col,
        width = vim.api.nvim_win_get_width(win_id),
        height = vim.api.nvim_win_get_height(win_id),
      })
    end
  end

  table.sort(wins, function(a, b)
    if a.row ~= b.row then
      return a.row < b.row
    end
    return a.col < b.col
  end)

  for i, slot in ipairs(wins) do
    slot.index = i
  end

  return wins
end

---@param wins MergeSlot[]
---@return table
local function group_by_row(wins)
  if #wins == 0 then
    return {}
  end

  local groups = {}
  local current = { wins[1] }
  local band_top = wins[1].row

  for i = 2, #wins do
    local win = wins[i]
    if win.row == band_top then
      table.insert(current, win)
    else
      table.insert(groups, current)
      current = { win }
      band_top = win.row
    end
  end
  table.insert(groups, current)
  return groups
end

---@param wins MergeSlot[]
---@return number
local function ref_width(wins)
  local min ---@type number|nil
  for _, slot in ipairs(wins) do
    if slot.width > 0 then
      min = min and math.min(min, slot.width) or slot.width
    end
  end
  return min or 1
end

---@param tree table
---@param ref number
local function annotate_render_units(tree, ref)
  if tree.type == 'leaf' then
    if tree.slot and tree.slot.width > 0 then
      tree.render_units = math.max(1, math.floor(tree.slot.width / ref + 0.5))
    else
      tree.render_units = 1
    end
    return
  end

  for _, child in ipairs(tree.children) do
    annotate_render_units(child, ref)
  end
end

---@param tree table
---@return number
local function sum_render_units(tree)
  if tree.type == 'leaf' then
    return tree.render_units or 1
  end
  if tree.type == 'vsplit' then
    local total = 0
    for _, child in ipairs(tree.children) do
      total = total + sum_render_units(child)
    end
    return total
  end
  if tree.type == 'hsplit' and tree.children[1] then
    return sum_render_units(tree.children[1])
  end
  return 1
end

--- Lone bottom-row pane spans the row above (git mergetool MERGED layout).
---@param tree table
local function adjust_bottom_span(tree)
  if tree.type == 'hsplit' and #tree.children == 2 then
    adjust_bottom_span(tree.children[1])
    adjust_bottom_span(tree.children[2])
    local bottom = tree.children[2]
    if bottom.type == 'leaf' and bottom.slot then
      local top_span = sum_render_units(tree.children[1])
      bottom.render_units = math.max(bottom.render_units or 1, top_span)
    end
    return
  end

  if tree.children then
    for _, child in ipairs(tree.children) do
      adjust_bottom_span(child)
    end
  end
end

---@param wins MergeSlot[]
---@return table
local function build_tree(wins)
  if #wins == 0 then
    return { type = 'leaf', slot = nil }
  end
  if #wins == 1 then
    return { type = 'leaf', slot = wins[1] }
  end

  local row_groups = group_by_row(wins)
  if #row_groups > 1 then
    local children = {}
    for _, group in ipairs(row_groups) do
      table.insert(children, build_tree(group))
    end
    return { type = 'hsplit', children = children }
  end

  table.sort(wins, function(a, b)
    return a.col < b.col
  end)

  if #wins > 1 then
    local children = {}
    for _, win in ipairs(wins) do
      table.insert(children, build_tree({ win }))
    end
    return { type = 'vsplit', children = children }
  end

  return { type = 'leaf', slot = wins[1] }
end

---@param exclude_win_id number|nil
---@param tracked_win number|nil
---@return table
function M.get_layout(exclude_win_id, tracked_win)
  local slots = collect_windows(exclude_win_id)
  local tree = build_tree(slots)
  if #slots > 0 then
    annotate_render_units(tree, ref_width(slots))
    adjust_bottom_span(tree)
  end

  local active_index = 1
  if tracked_win then
    for _, slot in ipairs(slots) do
      if slot.win_id == tracked_win then
        active_index = slot.index
        break
      end
    end
  elseif #slots > 0 then
    local current = vim.api.nvim_get_current_win()
    for _, slot in ipairs(slots) do
      if slot.win_id == current then
        active_index = slot.index
        break
      end
    end
  end

  local other_tabs = 0
  local current_tab = vim.api.nvim_get_current_tabpage()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if tab ~= current_tab then
      local wins = vim.api.nvim_tabpage_list_wins(tab)
      if #wins > 0 then
        other_tabs = other_tabs + 1
      end
    end
  end

  return {
    slots = slots,
    tree = tree,
    active_index = active_index,
    other_tabs = other_tabs,
  }
end

---@param layout table
---@return table<number, number>
function M.slot_map(layout)
  local map = {}
  for _, slot in ipairs(layout.slots) do
    map[slot.index] = slot.win_id
  end
  return map
end

return M
