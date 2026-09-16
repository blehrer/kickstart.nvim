local detect = require('merge-tool-help.detect')

local M = {}

local CELL_W = 7
local CELL_H = 3

---@param n number
---@param width number
---@return string
local function center_text(n, width)
  local text = tostring(n)
  local pad = math.max(0, width - #text)
  local left = math.floor(pad / 2)
  return string.rep(' ', left) .. text .. string.rep(' ', pad - left)
end

---@param width number
---@param ch string
---@return string
local function hline(width, ch)
  return string.rep(ch or '-', width)
end

---@param lines string[]
---@param row number
---@param col number
---@param length number
---@param hl_group string
---@return table
local function mark(lines, row, col, length, hl_group)
  return {
    row = row,
    col = col,
    length = length,
    hl_group = hl_group,
  }
end

---@param interior_w number
---@param interior_h number
---@param label string|number
---@param active boolean
---@return string[], table[]
local function render_cell(interior_w, interior_h, label, active)
  local lines = {}
  local highlights = {}
  local total_w = interior_w + 2
  local label_str = type(label) == 'number' and center_text(label, interior_w) or label

  table.insert(lines, '+' .. hline(interior_w) .. '+')
  local middle_row = math.ceil(interior_h / 2)
  for r = 1, interior_h do
    local inner
    if type(label) == 'number' and r == middle_row then
      inner = label_str
    else
      inner = string.rep(' ', interior_w)
    end
    table.insert(lines, '|' .. inner .. '|')
    if active and type(label) == 'number' and r == middle_row then
      local text = tostring(label)
      local pad = math.max(0, interior_w - #text)
      local left = math.floor(pad / 2)
      table.insert(highlights, mark(lines, #lines - 1, 1 + left, #text, 'MergeToolHelpActive'))
    end
  end
  table.insert(lines, '+' .. hline(interior_w) .. '+')
  return lines, highlights
end

---@param a string[]
---@param b string[]
---@return string[]
local function hstack(a, b)
  local out = {}
  local max_h = math.max(#a, #b)
  for i = 1, max_h do
    local left = a[i] or ''
    local right = b[i] or ''
    if left == '' then
      table.insert(out, right)
    elseif right == '' then
      table.insert(out, left)
    else
      table.insert(out, left .. right)
    end
  end
  return out
end

---@param a string[]
---@param b string[]
---@return string[]
local function vstack(a, b)
  local out = {}
  for _, line in ipairs(a) do
    table.insert(out, line)
  end
  for _, line in ipairs(b) do
    table.insert(out, line)
  end
  return out
end

---@param tree table
---@param active_index number
---@param scale number
---@return string[], table[]
function M.render_tree(tree, active_index, scale)
  scale = scale or 1
  local iw = math.max(5, CELL_W * scale)
  local ih = math.max(3, CELL_H * scale)

  if tree.type == 'leaf' then
    if not tree.slot then
      return { '(no windows)' }, {}
    end
    local active = tree.slot.index == active_index
    local units = tree.render_units or 1
    local iw = math.max(5, CELL_W * units * scale)
    return render_cell(iw, ih, tree.slot.index, active)
  end

  local parts = {}
  local all_hl = {}
  local y_offset = 0

  for i, child in ipairs(tree.children) do
    local lines, hl = M.render_tree(child, active_index, scale)
    table.insert(parts, { lines = lines, hl = hl })
  end

  if #parts == 0 then
    return {}, {}
  end

  local result = parts[1].lines
  for _, h in ipairs(parts[1].hl) do
    table.insert(all_hl, h)
  end

  for i = 2, #parts do
    local prev_offset = #result
    if tree.type == 'vsplit' then
      local col_offset = vim.fn.strdisplaywidth(result[1] or '')
      result = hstack(result, parts[i].lines)
      for _, h in ipairs(parts[i].hl) do
        table.insert(all_hl, {
          row = h.row,
          col = h.col + col_offset,
          length = h.length,
          hl_group = h.hl_group,
        })
      end
    else
      result = vstack(result, parts[i].lines)
      for _, h in ipairs(parts[i].hl) do
        table.insert(all_hl, {
          row = h.row + prev_offset,
          col = h.col,
          length = h.length,
          hl_group = h.hl_group,
        })
      end
    end
  end

  return result, all_hl
end

---@param slot table|nil
---@return string[]
function M.pane_detail(slot)
  if not slot then
    return { '', 'No pane selected.' }
  end

  local role = slot.role
  if detect.is_output_buf(slot.bufnr) then
    role = 'MERGED'
  end

  local info = detect.role_info(role)
  local display_name = vim.fn.fnamemodify(slot.bufname, ':t')
  if display_name == '' then
    display_name = slot.bufname
  end

  local edit = info.edit
  if role == 'UNKNOWN' then
    edit = vim.bo[slot.bufnr].modifiable and 'MAYBE (modifiable)' or 'NO'
  end

  return {
    '',
    string.format('%d - %s', slot.index, role),
    'Buffer: ' .. display_name,
    'Should I edit this? ' .. edit,
    'Why? ' .. info.why,
  }
end

---@param options_lines string[]
---@return string[]
function M.options_detail(options_lines)
  local lines = { '', '── Options (o to toggle pane view) ──' }
  for _, line in ipairs(options_lines) do
    table.insert(lines, line)
  end
  table.insert(lines, '')
  table.insert(lines, '[i] whitespace  [h] indent  [a] diff algo')
  table.insert(lines, '[d] conflict style  [f] favor  [m] merge algo')
  table.insert(lines, '[r] recompute merge  [1-9] select  [Enter] go  [q] close')
  return lines
end

---@param diagram string[]
---@param detail string[]
---@param footer string|nil
---@return string[]
function M.compose(diagram, detail, footer)
  local lines = {}
  for _, line in ipairs(diagram) do
    table.insert(lines, line)
  end
  for _, line in ipairs(detail) do
    table.insert(lines, line)
  end
  if footer and footer ~= '' then
    table.insert(lines, '')
    table.insert(lines, footer)
  end
  return lines
end

return M
