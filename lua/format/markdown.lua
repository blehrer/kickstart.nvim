local M = {}

local ATOMIC_PATTERNS = {
  '!?%b[]%b()',
  '!?%[%[[^%]]+%]%]',
  '`[^`]*`',
}

local function is_table_line(line)
  if line:match('^%s*|') then
    return true
  end
  return line:match('^%s*:?%-+:') and line:find('|', 1, true) ~= nil
end

local function display_width(s)
  return vim.fn.strdisplaywidth(s)
end

--- ponytail: textwidth(lnum) returns 0 unless 'formatoptions' has 't'; Neovim may lack textwidth().
local function effective_width()
  local width = vim.bo.textwidth
  if width <= 0 then
    width = vim.o.textwidth
  end
  if width <= 0 then
    local ok, tw = pcall(vim.fn.textwidth)
    if ok and tw and tw > 0 then
      width = tw
    end
  end
  if width <= 0 then
    local win = vim.api.nvim_get_current_win()
    if win and vim.api.nvim_win_is_valid(win) then
      width = vim.api.nvim_win_get_width(win) - vim.o.wrapmargin
    end
  end
  return width
end

---@param text string
---@return string[]
local function tokenize(text)
  local tokens = {}
  local pos = 1
  while pos <= #text do
    if text:sub(pos, pos):match('%s') then
      pos = pos + 1
    else
      local matched = false
      for _, pat in ipairs(ATOMIC_PATTERNS) do
        local s, e = text:find(pat, pos)
        if s == pos then
          tokens[#tokens + 1] = text:sub(s, e)
          pos = e + 1
          matched = true
          break
        end
      end
      if not matched then
        local s, e = text:find('%S+', pos)
        if not s then
          break
        end
        tokens[#tokens + 1] = text:sub(s, e)
        pos = e + 1
      end
    end
  end
  return tokens
end

---@param line string
---@return string first_indent, string cont_indent
local function leading_markup(line)
  local bullet = line:match('^(%s*[-*+]%s+)')
  if bullet then
    return bullet, bullet:gsub('%S', ' ') .. '  '
  end
  local ordered = line:match('^(%s*%d+%.%s+)')
  if ordered then
    return ordered, ordered:gsub('%S', ' ') .. '  '
  end
  local quote = line:match('^(>+%s*)')
  if quote then
    return quote, quote
  end
  local ws = line:match('^(%s*)') or ''
  return ws, ws
end

---@param tokens string[]
---@param width integer
---@param first_indent string
---@param cont_indent string
---@return string[]
local function wrap_tokens(tokens, width, first_indent, cont_indent)
  local lines = {}
  local line = first_indent
  local indent_width = display_width(first_indent)

  local function has_body()
    return display_width(line) > indent_width
  end

  local function flush()
    lines[#lines + 1] = line
    line = cont_indent
    indent_width = display_width(cont_indent)
  end

  for _, tok in ipairs(tokens) do
    local sep = has_body() and ' ' or ''
    local candidate = line .. sep .. tok

    if has_body() and display_width(candidate) > width then
      flush()
      candidate = line .. tok
    end

    line = candidate
  end

  if line ~= '' then
    lines[#lines + 1] = line
  end

  if #lines == 0 then
    lines[1] = first_indent
  end

  return lines
end

---@param lines string[]
---@param width integer
---@return string[]
local function format_prose_block(lines, width)
  if #lines == 0 then
    return lines
  end

  local result = {}
  local block = {}

  local function flush_block()
    if #block == 0 then
      return
    end
    local first_indent, cont_indent = leading_markup(block[1])
    local parts = {}
    for _, ln in ipairs(block) do
      parts[#parts + 1] = vim.trim(ln:sub(#first_indent + 1))
    end
    local text = table.concat(parts, ' ')
    if text == '' then
      vim.list_extend(result, block)
    else
      vim.list_extend(result, wrap_tokens(tokenize(text), width, first_indent, cont_indent))
    end
    block = {}
  end

  for _, ln in ipairs(lines) do
    if ln:match('^%s*$') then
      flush_block()
      result[#result + 1] = ''
    else
      block[#block + 1] = ln
    end
  end
  flush_block()
  return result
end

--- Reflow markdown prose while keeping links, images, and table rows intact.
---@param lines string[]
---@param opts? { width?: integer }
---@return string[]
function M.format_line_range(lines, opts)
  opts = opts or {}
  local width = opts.width or 80
  if width <= 0 then
    return lines
  end

  local out = {}
  local prose = {}

  local function flush_prose()
    if #prose == 0 then
      return
    end
    vim.list_extend(out, format_prose_block(prose, width))
    prose = {}
  end

  for _, ln in ipairs(lines) do
    if is_table_line(ln) then
      flush_prose()
      out[#out + 1] = ln
    else
      prose[#prose + 1] = ln
    end
  end
  flush_prose()
  return out
end

function M.formatexpr()
  local lnum = vim.v.lnum
  local count = vim.v.count
  local width = effective_width()
  if width <= 0 then
    return 1
  end

  local end_lnum = lnum + count - 1
  local lines = vim.api.nvim_buf_get_lines(0, lnum - 1, end_lnum, false)
  local formatted = M.format_line_range(lines, { width = width })

  vim.api.nvim_buf_set_lines(0, lnum - 1, end_lnum, false, formatted)
  return 0
end

return M
