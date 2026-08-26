local M = {}

local QUERY = 'Query'

---@param node vim.treesitter.Node
---@param field_name string
---@return vim.treesitter.Node?
local function field_node(node, field_name)
  local field = node:field(field_name)
  if type(field) == 'table' and field[1] then
    return field[1]
  end
end

---@param node vim.treesitter.Node
---@param typ string
---@return vim.treesitter.Node?
local function ancestor_of_type(node, typ)
  while node do
    if node:type() == typ then
      return node
    end
    node = node:parent()
  end
end

---@param node vim.treesitter.Node
---@param row integer
---@param col integer
local function contains_pos(node, row, col)
  local sr, sc, er, ec = node:range()
  if row < sr or row > er then
    return false
  end
  if row == sr and col < sc then
    return false
  end
  if row == er and col >= ec then
    return false
  end
  return true
end

---@param bufnr integer
---@param node vim.treesitter.Node
---@return string?, 'string'|'text_block'?
local function decode_sql_literal(bufnr, node)
  if node:type() ~= 'string_literal' then
    return
  end

  for _, child in ipairs(node:named_children()) do
    if child:type() == 'multiline_string_fragment' then
      return vim.trim(vim.treesitter.get_node_text(child, bufnr), '\n'), 'text_block'
    end
    if child:type() == 'string_fragment' then
      return vim.treesitter.get_node_text(child, bufnr), 'string'
    end
  end
end

---@param bufnr integer
---@param string_node vim.treesitter.Node
---@return vim.treesitter.Node?, vim.treesitter.Node?
local function query_value_string(bufnr, string_node)
  local parent = string_node:parent()
  if not parent then
    return
  end

  local annotation
  if parent:type() == 'element_value_pair' then
    local key = field_node(parent, 'key')
    if not key or vim.treesitter.get_node_text(key, bufnr) ~= 'value' then
      return
    end
    annotation = ancestor_of_type(parent, 'annotation')
  elseif parent:type() == 'annotation_argument_list' then
    annotation = ancestor_of_type(parent, 'annotation')
  else
    return
  end

  if not annotation then
    return
  end

  local ann_name = field_node(annotation, 'name')
  if not ann_name or vim.treesitter.get_node_text(ann_name, bufnr) ~= QUERY then
    return
  end

  return annotation, string_node
end

---@param bufnr integer
---@param row integer
---@param col integer
---@return { string_node: vim.treesitter.Node, style: 'string'|'text_block', sql: string }?
local function target_at(bufnr, row, col)
  if vim.bo[bufnr].filetype ~= 'java' then
    return
  end

  if not pcall(vim.treesitter.get_parser, bufnr, 'java') then
    return
  end

  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col }, lang = 'java' })
  while node do
    if node:type() == 'string_literal' and contains_pos(node, row, col) then
      local _, string_node = query_value_string(bufnr, node)
      if string_node then
        local sql, style = decode_sql_literal(bufnr, string_node)
        if sql and style then
          return { string_node = string_node, style = style, sql = sql }
        end
      end
    end
    node = node:parent()
  end
end

---@param bufnr integer
---@param lnum integer 0-indexed
---@return string
local function line_indent(bufnr, lnum)
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ''
  return line:match('^(%s*)') or ''
end

---@param sql string
---@param style 'string'|'text_block'
---@param bufnr integer
---@param string_node vim.treesitter.Node
---@return string?
local function encode_sql(sql, style, bufnr, string_node)
  local lines = vim.split(vim.trim(sql, '\n'), '\n', { plain = true })
  if #lines == 0 then
    return
  end

  local multiline = #lines > 1 or style == 'text_block'
  if not multiline then
    local escaped = lines[1]:gsub('\\', '\\\\'):gsub('"', '\\"')
    return '"' .. escaped .. '"'
  end

  local sr = string_node:range()
  local base = line_indent(bufnr, sr)
  local inner = base .. '    '
  local out = { '"""' }
  for _, line in ipairs(lines) do
    table.insert(out, inner .. line)
  end
  table.insert(out, base .. '"""')
  return table.concat(out, '\n')
end

---@param sql string
---@return string?, string?
local function format_sql(sql)
  local cmd = vim.fn.executable('sql-formatter') == 1 and { 'sql-formatter' }
    or { 'npx', '-y', 'sql-formatter' }
  local result = vim.system(cmd, { stdin = sql, text = true }):wait()
  if result.code ~= 0 then
    return nil, (result.stderr or 'sql-formatter failed'):gsub('\n$', '')
  end
  return vim.trim(result.stdout or ''), nil
end

---@param target { string_node: vim.treesitter.Node, style: 'string'|'text_block', sql: string }
local function apply_format(bufnr, target)
  local formatted, err = format_sql(target.sql)
  if not formatted then
    vim.notify(err or 'sql-formatter failed', vim.log.levels.ERROR)
    return
  end

  local new_text = encode_sql(formatted, target.style, bufnr, target.string_node)
  if not new_text then
    return
  end

  local sr, sc, er, ec = target.string_node:range()
  vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, vim.split(new_text, '\n', { plain = true }))
end

---@return config.code_actions.Action[]
function M.actions(bufnr, row, col)
  local target = target_at(bufnr, row, col)
  if not target then
    return {}
  end

  return {
    {
      title = 'Format SQL (@Query value)',
      kind = 'source.format',
      apply = function()
        apply_format(bufnr, target)
      end,
    },
  }
end

return M
